class Myc::Backend::QBE::Builder < Myc::Backend::AbstractBuilder
  getter func_links : Hash(String, Type::Fn)
  getter global_links : Hash(String, Value)
  getter string_constants : Hash(String, String)
  getter data_io : IO::Memory
  @type_translator : TypeTranslator?
  @data_type_translator : DataTypeTranslator?

  def initialize(@backend, @layout)
    super(@backend, @layout)

    @data_io = IO::Memory.new
    @str_counter = 0
    @label_counter = 0
    @string_constants = Hash(String, String).new
    @func_links = Hash(String, Type::Fn).new
    @global_links = Hash(String, Value).new
    @funcs = Array(Func).new
  end

  def type_translator
    @type_translator ||= TypeTranslator.new(self)
  end

  def data_type_translator
    @data_type_translator ||= DataTypeTranslator.new(self)
  end

  def func_register(name : String, func_def : Mod::FuncDef)
    @func_links[name] = func_def.type_fn
  end

  def global_register(mod : Mod, global : Mod::GlobalDef)
    g = Value.new(BBVal.new("$#{global.name}"), global.type, Value::MM::Ref,
      global.constant ? Value::PP::GlobalConstant.new(global.name) : Value::PP::Global.new(global.name))
    @global_links[global.name] = g

    return unless global.initial_keyword

    visibility = "export "

    if global.private_flag
      visibility = ""
    end

    values = [] of Tuple(String, String)
    if global.initial_keyword && global.initial_values.size > 0
      vp = AbstractBuilder::ValuesParser.new(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
      qbe_flatten_init(values, vp.parse)
    else
      zero_flatten(values, global.type)
    end

    @data_io << "#{visibility}data $#{global.name} = { "
    values.each_with_index do |(type_s, val_s), index|
      @data_io << ", " if index != 0
      @data_io << type_s
      @data_io << ' '
      @data_io << val_s
    end
    @data_io << "}\n"
  end

  def qbe_flatten_init(res : Array(Tuple(String, String)), init : InitValue)
    case init
    when InitValue::StructInit
      struct_type = init.type.as(Type::StructType)
      offset = 0_u64
      init.fields.each_with_index do |f, i|
        field_offset = layout.field_offset(struct_type, i.to_u64)
        res << {"z", (field_offset - offset).to_s} if field_offset > offset
        qbe_flatten_init(res, f)
        offset = field_offset + layout.size_of(f.type)
      end
      struct_size = layout.size_of(struct_type)
      res << {"z", (struct_size - offset).to_s} if struct_size > offset
    when InitValue::FlatInit
      init.elements.each { |e| qbe_flatten_init(res, e) }
    when InitValue::FlatStr
      init.str.each_byte { |b| res << {"b", b.to_s} }
    when InitValue::Intval
      res << {qbe_data_type(init.type), init.val.to_s}
    when InitValue::Boolval
      res << {qbe_data_type(init.type), init.val ? "1" : "0"}
    when InitValue::F32
      res << {qbe_data_type(init.type), sprintf("s_%a", init.val)}
    when InitValue::F64
      res << {qbe_data_type(init.type), sprintf("d_%a", init.val)}
    when InitValue::Str
      res << {qbe_data_type(init.type), string_constant(init.str)}
    when InitValue::Zero
      res << {qbe_data_type(init.type), "0"}
    when InitValue::GlobalRef, InitValue::FnRef
      res << {qbe_data_type(init.type), "$#{init.name}"}
    else
      raise "unreachable"
    end
  end

  private def qbe_data_type(t : Type) : String
    data_type_translator.translate(t)
  end

  def init_value(ival : InitValue) : Value
    values = [] of Tuple(String, String)
    qbe_flatten_init(values, ival)
    Value.new(BBVal.new(values[0][1]), ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  private def zero_flatten(res : Array(Tuple(String, String)), type : Type)
    case type
    when Type::StructType
      size = layout.size_of(type)
      res << {"z", size.to_s} if size > 0
    when Type::FlatType
      type.elements_count.times { zero_flatten(res, type.target_type) }
    when Type::EnumType
      if index_type = type.index_type
        zero_flatten(res, index_type)
        @layout.enum_payload_count(type).times { res << {qbe_data_type(index_type), "0"} }
      else
        @layout.enum_payload_count(type).times { res << {qbe_data_type(type.payload_type.not_nil!.target_type), "0"} }
      end
    when Type::PtrType, Type::Fn, Type::IntType, Type::FloatType, Type::BoolType
      res << {qbe_data_type(type), "0"}
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

  def qbe_type(type : Type) : String
    type_translator.translate(type)
  end

  def string_constant(str : String) : String
    @string_constants.put_if_absent(str) do
      name = "str_#{@str_counter}"
      @str_counter += 1
      @data_io << "data $#{name} = { b \"#{AbstractBuilder.escaped_string(str)}\", b 0 }\n"
      "$#{name}"
    end
  end

  def new_label(prefix : String) : String
    @label_counter += 1
    "#{prefix}_#{@label_counter}"
  end

  def copy_io(from : IO, to : IO)
    from.rewind
    IO.copy(from, to)
  end

  def new_func(func_def : Mod::FuncDef) : AbstractFunc
    f = Func.new(self, func_def)
    @funcs << f
    f
  end

  def save(filename : String)
    File.open(filename, "w") do |f|
      copy_io(@data_io, f)

      @funcs.each do |fb|
        copy_io(fb.body_io, f)
      end
    end
  end
end
