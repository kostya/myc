class Myc::Backend::GM::Builder < Myc::Backend::AbstractBuilder
  getter func_links : Hash(String, Type::Fn)
  getter func_decls : Hash(String, String)
  getter global_links : Hash(String, Value)
  getter string_constants : Hash(String, String)
  getter data_io : IO::Memory
  getter layout : Layout
  @type_translator : TypeTranslator?
  @data_type_translator : DataTypeTranslator?

  def initialize(@backend, @layout)
    super(@backend, @layout)

    @data_io = IO::Memory.new
    @str_counter = 0
    @string_constants = Hash(String, String).new
    @func_links = Hash(String, Type::Fn).new
    @func_decls = Hash(String, String).new
    @global_links = Hash(String, Value).new
    @funcs = Array(Func).new
  end

  def type_translator
    @type_translator ||= TypeTranslator.new(self, @backend.typer)
  end

  def data_type_translator
    @data_type_translator ||= DataTypeTranslator.new(self, @backend.typer)
  end

  def func_register(name : String, func_def : Mod::FuncDef)
    @func_links[name] = func_def.type_fn
  end

  def func_link(name : String, type_fn : Type::Fn) : Type::Fn
    return type_fn if @funcs.any? { |f| f.func_def.name == name }

    @func_decls.put_if_absent(name) do
      params = type_fn.args.map_with_index { |t, i| "%a#{i} : #{lowir_type(t)}" }.join(", ")
      ret = lowir_type(type_fn.ret)
      meta = [] of String
      meta << "arity=variadic" if type_fn.vaarg
      meta << "linkage=c"
      meta << "binding=strong"
      "declare function @#{name}(#{params}) -> #{ret} [#{meta.join(", ")}]"
    end
    @func_links[name] = type_fn
    type_fn
  end

  def global_register(mod : Mod, global : Mod::GlobalDef)
    g = Value.new(BBVal.new("@#{global.name}"), global.type, Value::MM::Ref,
      global.constant ? Value::PP::GlobalConstant.new(global.name) : Value::PP::Global.new(global.name))
    @global_links[global.name] = g

    unless global.initial_keyword
      @data_io << "declare global @#{global.name} : #{lowir_type(global.type)}\n"
      return
    end

    return unless global.initial_keyword

    meta = [] of String
    if global.private_flag
      meta << "binding=internal"
    else
      meta << "binding=strong"
    end

    values = [] of Tuple(String, String)
    if global.initial_keyword && global.initial_values.size > 0
      vp = AbstractBuilder::ValuesParser.new(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
      lowir_flatten_init(values, vp.parse)
    else
      zero_flatten(values, global.type)
    end

    @data_io << "global @#{global.name}"
    unless meta.empty?
      @data_io << " ["
      @data_io << meta.join(", ")
      @data_io << "]"
    end
    @data_io << " = {\n"
    values.each do |(type_s, val_s)|
      @data_io << "  "
      @data_io << type_s
      @data_io << ' '
      @data_io << val_s
      @data_io << '\n'
    end
    @data_io << "}\n"
  end

  def lowir_flatten_init(res : Array(Tuple(String, String)), init : InitValue)
    case init
    when InitValue::StructInit
      struct_type = init.type.as(Type::StructType)
      offset = 0_u64
      init.fields.each_with_index do |f, i|
        field_offset = layout.field_offset(struct_type, i.to_u64)
        res << {"zero", (field_offset - offset).to_s} if field_offset > offset
        lowir_flatten_init(res, f)
        offset = field_offset + layout.size_of(f.type)
      end
      struct_size = layout.size_of(struct_type)
      res << {"zero", (struct_size - offset).to_s} if struct_size > offset
    when InitValue::FlatInit
      init.elements.each { |e| lowir_flatten_init(res, e) }
    when InitValue::FlatStr
      init.str.each_byte { |b| res << {"i8", b.to_s} }
    when InitValue::Intval
      res << {lowir_data_type(init.type), init.val.to_s}
    when InitValue::Boolval
      res << {lowir_data_type(init.type), init.val ? "1" : "0"}
    when InitValue::F32
      res << {lowir_data_type(init.type), sprintf("%a", init.val) + "f"}
    when InitValue::F64
      res << {lowir_data_type(init.type), sprintf("%a", init.val)}
    when InitValue::Str
      res << {"ptr", "addr #{string_constant(init.str)}"}
    when InitValue::Zero
      val = if init.type.is_a?(Type::PtrType) || init.type.is_a?(Type::Fn)
              "nullptr"
            else
              "0"
            end
      res << {lowir_data_type(init.type), val}
    when InitValue::GlobalRef, InitValue::FnRef
      res << {"ptr", "addr @#{init.name}"}
    else
      raise "unreachable"
    end
  end

  private def lowir_data_type(t : Type) : String
    data_type_translator.translate(t)
  end

  def init_value(ival : InitValue) : Value
    values = [] of Tuple(String, String)
    lowir_flatten_init(values, ival)

    Value.new(BBVal.new(values[0][1]), ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  private def zero_flatten(res : Array(Tuple(String, String)), type : Type)
    case type
    when Type::StructType
      size = layout.size_of(type)
      res << {"zero", size.to_s} if size > 0
    when Type::FlatType
      type.elements_count.times { zero_flatten(res, type.target_type) }
    when Type::EnumType
      _payload = type.payload_type.not_nil!
      pcount = _payload.elements_count
      if index_type = type.index_type
        zero_flatten(res, index_type)
        pcount.times { res << {lowir_data_type(type.payload_type.not_nil!.target_type), "0"} }
      else
        pcount.times { res << {lowir_data_type(type.payload_type.not_nil!.target_type), "0"} }
      end
    when Type::PtrType, Type::Fn
      res << {"ptr", "nullptr"}
    when Type::IntType, Type::FloatType, Type::BoolType
      res << {lowir_data_type(type), "0"}
    else
      raise "unexpected type in global data: #{type.class}"
    end
  end

  def find_global(name : String) : Value?
    @global_links[name]?
  end

  def emit_type(str : String)
    @data_io << str
  end

  def lowir_type(type : Type) : String
    type_translator.translate(type)
  end

  def string_constant(str : String) : String
    @string_constants.put_if_absent(str) do
      name = "str_#{@str_counter}"
      @str_counter += 1
      @data_io << "global @#{name} [storage=readonly, binding=internal] = {\n"
      str.each_byte do |b|
        @data_io << "  i8 "
        @data_io << b
        @data_io << '\n'
      end
      @data_io << "  i8 0\n"
      @data_io << "}\n"
      "@#{name}"
    end
  end

  def copy_io(from : IO, to : IO)
    from.rewind
    IO.copy(from, to)
  end

  def new_func(func_def : Mod::FuncDef, header_mod : Mod) : AbstractFunc
    f = Func.new(self, func_def, header_mod)
    @funcs << f
    f
  end

  def save(filename : String)
    File.open(filename, "w") do |f|
      defined_names = @funcs.map { |fb| fb.func_def.name }.to_set
      @func_decls.each do |name, decl|
        next if defined_names.includes?(name)
        f << decl << '\n'
      end
      copy_io(@data_io, f)
      @funcs.each { |fb| copy_io(fb.body_io, f) }
    end
  end
end
