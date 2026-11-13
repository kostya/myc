class Myc::Backend::GM::Builder < Myc::Backend::AbstractBuilder
  getter func_links : Hash(String, Type::Fn)
  getter global_links : Hash(String, Value)
  @native : NativeModule
  property current_func : Func?
  @type_translator : TypeTranslator?

  def initialize(@backend, @layout)
    super(@backend, @layout)
    @native = NativeModule.new(@layout.target.os.darwin? ? 1_u32 : 0_u32)
    @symbols = Hash(String, UInt32).new
    @signatures = Hash(String, UInt32).new
    @defined = Set(String).new
    @used = Hash(String, Type::Fn).new
    @finished = false
    @func_links = Hash(String, Type::Fn).new
    @global_links = Hash(String, Value).new
    @string_constants = Hash(String, LibGM::Value).new
  end

  def handle : LibGM::Module*
    @native.pointer
  end

  def close
    @native.close
  end

  def check(result : Int32)
    raise "GM: #{String.new(NativeAPI.error(handle))}" if result == 0
  end

  private def check_id(id : UInt32) : UInt32
    raise "GM: #{String.new(NativeAPI.error(handle))}" if id == NO_ID
    id
  end

  def symbol(name : String) : UInt32
    @symbols[name] ||= check_id(NativeAPI.symbol(handle, name, name.bytesize))
  end

  def signature(type_fn : Type::Fn) : UInt32
    @signatures[type_fn.id_name] ||= begin
      args = type_fn.args.map { |t| lowir_type(t) }
      check_id(NativeAPI.signature(handle, lowir_type(type_fn.ret), args.to_unsafe, args.size, type_fn.vaarg ? 1 : 0))
    end
  end

  def func_register(name : String, func_def : Mod::FuncDef)
    @func_links[name] = func_def.type_fn
  end

  def func_link(name : String, type_fn : Type::Fn) : Type::Fn
    @func_links[name] = type_fn
    @used[name] = type_fn
    type_fn
  end

  def new_func(func_def : Mod::FuncDef, header_mod : Mod) : AbstractFunc
    @defined << func_def.name
    binding = func_def.private? ? 1 : 2
    check(NativeAPI.function(handle, symbol(func_def.name), signature(func_def.type_fn), binding, 1))
    Func.new(self, func_def, header_mod)
  end

  private def finish
    return if @finished
    # Forward symbol IDs need no declaration while bodies are being built.
    # Publish only surviving externals once all definitions are known. This
    # also keeps definition order identical to the original text producer.
    @used.each do |name, type_fn|
      next if @defined.includes?(name)
      check(NativeAPI.function(handle, symbol(name), signature(type_fn), 2, 0))
    end
    @finished = true
  end

  def lowir_type(type : Type) : UInt64
    (@type_translator ||= TypeTranslator.new(self, @backend.typer)).translate(type)
  end

  def find_global(name : String) : Value?
    @global_links[name]?
  end

  def global_register(mod : Mod, global : Mod::GlobalDef)
    id = symbol(global.name)
    @global_links[global.name] = Value.new(BBVal.new(GM.ir_value(IRKind::Symbol, id)), global.type, Value::MM::Ref,
      global.constant ? Value::PP::GlobalConstant.new(global.name) : Value::PP::Global.new(global.name))
    declaration = !global.initial_keyword
    items = [] of LibGM::DataItem
    unless declaration
      if global.initial_values.size > 0
        vp = AbstractBuilder::ValuesParser.new(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
        flatten(items, vp.parse)
      else
        zero_flatten(items, global.type)
      end
    end
    check(NativeAPI.global(handle, id, declaration ? lowir_type(global.type) : 0_u64,
      global.private_flag ? 1 : 2, 0, items.to_unsafe, items.size, declaration ? 1 : 0))
  end

  private def zero_data(size) : LibGM::DataItem
    LibGM::DataItem.new(kind: 2, amount: size.to_i64)
  end

  private def scalar_data(type : UInt64, low : UInt64, high = 0_u64) : LibGM::DataItem
    LibGM::DataItem.new(type: type, bits: LibGM::Literal.new(low: low, high: high))
  end

  private def address_data(id : UInt32) : LibGM::DataItem
    LibGM::DataItem.new(type: GM.ir_type(IRType::Ptr), kind: 1, symbol: id)
  end

  private def zero_flatten(items : Array(LibGM::DataItem), type : Type)
    case type
    when Type::StructType
      size = layout.size_of(type)
      items << zero_data(size) if size > 0
    when Type::FlatType
      type.elements_count.times { zero_flatten(items, type.target_type) }
    when Type::EnumType
      if index = type.index_type
        zero_flatten(items, index)
      end
      payload = type.payload_type.not_nil!
      payload.elements_count.times { items << scalar_data(lowir_type(payload.target_type), 0_u64) }
    when Type::PtrType, Type::Fn
      items << scalar_data(GM.ir_type(IRType::Ptr), 0_u64)
    when Type::IntType, Type::FloatType, Type::BoolType
      items << scalar_data(lowir_type(type), 0_u64)
    else
      raise "unexpected GM zero initializer #{type.class}"
    end
  end

  private def flatten(res : Array(LibGM::DataItem), init : InitValue)
    case init
    when InitValue::StructInit
      struct_type = init.type.as(Type::StructType)
      offset = 0_u64
      init.fields.each_with_index do |f, i|
        field_offset = layout.field_offset(struct_type, i.to_u64)
        res << zero_data(field_offset - offset) if field_offset > offset
        flatten(res, f)
        offset = field_offset + layout.size_of(f.type)
      end
      size = layout.size_of(struct_type)
      res << zero_data(size - offset) if size > offset
    when InitValue::FlatInit
      init.elements.each { |e| flatten(res, e) }
    when InitValue::FlatStr
      init.str.each_byte { |b| res << scalar_data(GM.ir_type(IRType::I8), b.to_u64) }
    when InitValue::Intval
      res << scalar_data(lowir_type(init.type), init.val.to_u64!, init.val < 0 ? UInt64::MAX : 0_u64)
    when InitValue::Boolval
      res << scalar_data(lowir_type(init.type), init.val ? 1_u64 : 0_u64)
    when InitValue::F32
      res << scalar_data(lowir_type(init.type), init.val.unsafe_as(UInt32).to_u64)
    when InitValue::F64
      res << scalar_data(lowir_type(init.type), init.val.unsafe_as(UInt64))
    when InitValue::Str
      res << address_data(string_constant(init.str).index)
    when InitValue::GlobalRef, InitValue::FnRef
      res << address_data(symbol(init.name))
    when InitValue::Zero
      if init.type.needs_blit?
        res << zero_data(layout.size_of(init.type))
      else
        res << scalar_data(lowir_type(init.type), 0_u64)
      end
    else
      raise "unexpected GM initializer #{init.class}"
    end
  end

  def init_value(ival : InitValue) : Value
    func = @current_func.not_nil!
    raw = case ival
          when InitValue::Str
            string_constant(ival.str)
          when InitValue::GlobalRef, InitValue::FnRef
            GM.ir_value(IRKind::Symbol, symbol(ival.name))
          when InitValue::Intval
            bits = ival.val.to_u64!
            negative = ival.type.is_a?(Type::IntType) && ival.type.as(Type::IntType).bytes_count == 16 ? ival.val < 0 : bits.unsafe_as(Int64) < 0
            func.literal(IRKind::Integer, bits, negative ? UInt64::MAX : 0_u64)
          when InitValue::Boolval
            func.integer(ival.val ? 1 : 0)
          when InitValue::F32
            func.literal(IRKind::Float, ival.val.unsafe_as(UInt32).to_u64, 0_u64, IRType::F32)
          when InitValue::F64
            func.literal(IRKind::Float, ival.val.unsafe_as(UInt64), 0_u64, IRType::F64)
          when InitValue::Zero
            func.integer(0)
          else
            raise "unexpected GM immediate #{ival.class}"
          end
    address = ival.is_a?(InitValue::Str) || ival.is_a?(InitValue::GlobalRef) || ival.is_a?(InitValue::FnRef)
    Value.new(BBVal.new(raw, address), ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  def string_constant(str : String) : LibGM::Value
    @string_constants[str] ||= begin
      id = symbol("str_#{@string_constants.size}")
      items = str.bytes.map { |b| scalar_data(GM.ir_type(IRType::I8), b.to_u64) }
      items << scalar_data(GM.ir_type(IRType::I8), 0_u64)
      check(NativeAPI.global(handle, id, 0_u64, 1, 1, items.to_unsafe, items.size, 0))
      GM.ir_value(IRKind::Symbol, id)
    end
  end

  def save(filename : String)
    finish
    check(NativeAPI.write(handle, filename))
  end

  def compile(output : String, level : Int32)
    finish
    check(NativeAPI.compile(handle, level, 0))
    size = NativeAPI.object_size(handle).to_i
    File.write(output, Slice.new(NativeAPI.object_data(handle), size))
  end
end
