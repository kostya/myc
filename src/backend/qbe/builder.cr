class Myc::Backend::QBE::Builder < Myc::Backend::AbstractBuilder
  getter func_links : Hash(String, Type::Fn)
  getter global_links : Hash(String, Value)
  getter string_constants : Hash(String, String)
  getter data_io : IO::Memory
  @type_translator : TypeTranslator?

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

  def func_register(name : String, type_fn : Type::Fn)
    @func_links[name] = type_fn
  end

  def global_register(mod : Mod, global : Mod::GlobalDef)
    g = Value.new(BBVal.new("$#{global.name}"), global.type, Value::MM::Ref,
      global.constant ? Value::PP::GlobalConstant.new(global.name) : Value::PP::Global.new(global.name))
    @global_links[global.name] = g

    fields = if global.initial_keyword && global.initial_values.size > 0
               init = init_val(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
               qbe_flatten_init(init)
             else
               zero_flatten(global.type)
             end

    @data_io << "data $#{global.name} = { #{fields.map { |t, v| "#{qbe_type(t)} #{v}" }.join(", ")} }\n"
  end

  def qbe_flatten_init(init : InitValue) : Array(Tuple(Type, String))
    case init
    when InitValue::StructInit
      init.fields.flat_map { |f| qbe_flatten_init(f) }
    when InitValue::FlatInit
      init.elements.flat_map { |e| qbe_flatten_init(e) }
    when InitValue::FlatStr
      [{init.type, "\"#{init.str}\""}]
    when InitValue::Intval
      [{init.type, init.val.to_s}]
    when InitValue::Boolval
      [{init.type, init.val ? "1" : "0"}]
    when InitValue::F32
      [{init.type, sprintf("s_%a", init.val)}]
    when InitValue::F64
      [{init.type, sprintf("d_%a", init.val)}]
    when InitValue::Str
      [{init.type, string_constant(init.str)}]
    when InitValue::NullPtr
      [{init.type, "0"}]
    when InitValue::GlobalRef
      [{init.type, "$#{init.name}"}]
    when InitValue::FnRef
      [{init.type, "$#{init.name}"}]
    else
      raise "unreachable"
    end
  end

  def init_value(ival : InitValue) : Value
    vals = qbe_flatten_init(ival)
    val = vals.map { |_, v| v }.join(", ")
    Value.new(BBVal.new(val), ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  private def zero_flatten(type : Type) : Array(Tuple(Type, String))
    case type
    when Type::StructType
      type.data.flat_map { |t| zero_flatten(t) }.to_a
    when Type::FlatType
      type.elements_count.times.flat_map { zero_flatten(type.target_type) }.to_a
    when Type::EnumType
      fields = zero_flatten(type.index_type)
      payload_count = @layout.enum_payload_count(type)
      if payload_count > 0
        fields + payload_count.times.map { {type.index_type, "0"} }.to_a
      else
        fields
      end
    when Type::PtrType, Type::Fn, Type::IntType, Type::FloatType, Type::BoolType
      [{type.as(Type), "0"}]
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
      @data_io << "data $#{name} = { b \"#{escaped_string(str)}\", b 0 }\n"
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
