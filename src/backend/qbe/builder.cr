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

    fields = if global.initial_keyword && global.initial_values.size > 0
               vp = AbstractBuilder::ValuesParser.new(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
               fields1 = qbe_flatten_init(vp.parse, layout.alignment_of(global.type))
               fields1.map { |t, v| "#{t} #{v}" }
             else
               fields1 = zero_flatten(global.type)
               fields1.map { |t, v| "#{t} #{v}" }
             end

    @data_io << "#{visibility}data $#{global.name} = { #{fields.join(", ")} }\n"
  end

  def qbe_flatten_init(init : InitValue, align : UInt64? = nil) : Array(Tuple(String, String))
    res = case init
          when InitValue::StructInit
            init.fields.flat_map { |f| qbe_flatten_init(f, align) }
          when InitValue::FlatInit
            init.elements.flat_map { |e| qbe_flatten_init(e, align) }
          when InitValue::FlatStr
            [{qbe_data_type(init.type), "\"#{init.str}\""}]
          when InitValue::Intval
            [{qbe_data_type(init.type), init.val.to_s}]
          when InitValue::Boolval
            [{qbe_data_type(init.type), init.val ? "1" : "0"}]
          when InitValue::F32
            [{qbe_data_type(init.type), sprintf("s_%a", init.val)}]
          when InitValue::F64
            [{qbe_data_type(init.type), sprintf("d_%a", init.val)}]
          when InitValue::Str
            [{qbe_data_type(init.type), string_constant(init.str)}]
          when InitValue::Zero
            [{qbe_data_type(init.type), "0"}]
          when InitValue::GlobalRef
            [{qbe_data_type(init.type), "$#{init.name}"}]
          when InitValue::FnRef
            [{qbe_data_type(init.type), "$#{init.name}"}]
          else
            raise "unreachable"
          end

    if align && (layout.size_of(init.type) < 4 && align >= 4)
      res += [{"b", "0"}] * (4 - layout.size_of(init.type))
    end

    res
  end

  private def qbe_data_type(t : Type) : String
    data_type_translator.translate(t)
  end

  def init_value(ival : InitValue) : Value
    vals = qbe_flatten_init(ival)
    val = vals.map { |_, v| v }.join(", ")
    Value.new(BBVal.new(val), ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  private def zero_flatten(type : Type, align : UInt64? = nil) : Array(Tuple(String, String))
    res = case type
          when Type::StructType
            type.data.flat_map { |t| zero_flatten(t, align) }.to_a
          when Type::FlatType
            type.elements_count.times.flat_map { zero_flatten(type.target_type, align) }.to_a
          when Type::EnumType
            if index_type = type.index_type
              fields = zero_flatten(index_type, align)
              payload_count = @layout.enum_payload_count(type)
              if payload_count > 0
                fields + payload_count.times.map { {qbe_data_type(index_type), "0"} }.to_a
              else
                fields
              end
            else
              fields = [] of Tuple(String, String)
              payload_count = @layout.enum_payload_count(type)
              if payload_count > 0
                fields + payload_count.times.map { {qbe_data_type(type.payload_type.not_nil!.target_type), "0"} }.to_a
              else
                fields
              end
            end
          when Type::PtrType, Type::Fn, Type::IntType, Type::FloatType, Type::BoolType
            [{qbe_data_type(type), "0"}]
          else
            raise "unexpected type in global data: #{type.class}"
          end

    if align && (layout.size_of(type) < 4 && align >= 4)
      res += [{"b", "0"}] * (4 - layout.size_of(type))
    end

    res
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
