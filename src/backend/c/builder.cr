class Myc::Backend::C::Builder < Myc::Backend::AbstractBuilder
  @type_translator : TypeTranslator?
  @type_sorter : TypeSorter?

  getter func_links : Hash(String, Type::Fn)
  getter global_links : Hash(String, Value)

  def initialize(@backend, @layout)
    super(@backend, @layout)
    @func_links = Hash(String, Type::Fn).new
    @global_links = Hash(String, Value).new
    @temp_counter = 0
    @label_counter = 0
    @funcs = Array(Func).new
    @data_io = IO::Memory.new
  end

  def type_translator
    @type_translator ||= TypeTranslator.new(self)
  end

  def type_sorter
    @type_sorter ||= TypeSorter.new
  end

  def new_temp(pref = "t") : String
    @temp_counter += 1
    "#{pref}#{@temp_counter}"
  end

  def new_label(prefix : String) : String
    @label_counter += 1
    "#{prefix}_#{@label_counter}"
  end

  def c_type(type : Type) : String
    type_translator.translate(type)
  end

  def func_register(name : String, func_def : Mod::FuncDef)
    @data_io << func_head_str(name, func_def.type_fn, func_def.private?) << "; \n"
    @func_links[name] = func_def.type_fn
  end

  def global_register(mod : Mod, global : Mod::GlobalDef)
    g = Value.new(BBVal.new("#{global.name}"), global.type, Value::MM::Ref,
      global.constant ? Value::PP::GlobalConstant.new(global.name) : Value::PP::Global.new(global.name))
    @global_links[global.name] = g

    if global.private_flag
      @data_io << "static "
    else
      unless global.initial_keyword
        @data_io << "extern "
      end
    end

    @data_io << "const " if global.constant
    @data_io << c_type(global.type)
    @data_io << ' '
    @data_io << global.name

    if global.initial_keyword
      if global.initial_values.size > 0
        vp = AbstractBuilder::ValuesParser.new(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
        init = vp.parse

        @data_io << " = "
        c_constant(init, @data_io)
      end
    end

    @data_io << ";\n"
  end

  def c_constant(init : InitValue, io : IO)
    case init
    when InitValue::Intval
      io << init.val
    when InitValue::Boolval
      io << (init.val ? 1 : 0)
    when InitValue::F32
      case val = init.val
      when Float32::INFINITY
        io << "__builtin_inff()"
      when -Float32::INFINITY
        io << "-__builtin_inff()"
      when .nan?
        io << "__builtin_nanf(\"\")"
      else
        io << val
      end
    when InitValue::F64
      case val = init.val
      when Float64::INFINITY
        io << "__builtin_inf()"
      when -Float64::INFINITY
        io << "-__builtin_inf()"
      when .nan?
        io << "__builtin_nan(\"\")"
      else
        io << val
      end
    when InitValue::Str
      io << '"' << AbstractBuilder.escaped_string(init.str) << '"'
    when InitValue::Zero
      io << "NULL"
    when InitValue::GlobalRef
      io << '&' << init.name
    when InitValue::FnRef
      io << init.name
    when InitValue::StructInit
      io << '{'
      init.fields.each_with_index do |field, i|
        io << ", " if i > 0
        c_constant(field, io)
      end
      io << '}'
    when InitValue::FlatInit
      io << '{'
      init.elements.each_with_index do |elem, i|
        io << ", " if i > 0
        c_constant(elem, io)
      end
      io << '}'
    when InitValue::FlatStr
      io << '"' << AbstractBuilder.escaped_string(init.str) << '"'
    end
  end

  def init_value(ival : InitValue) : Value
    val = String.build { |s| c_constant(ival, s) }
    Value.new(BBVal.new(val), ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  def find_global(name : String) : Value?
    @global_links[name]?
  end

  def save(filename : String)
    inspect_type_fns.each do |name, func_def|
      func_register(name, func_def)
    end

    type_sorter.sort!

    File.open(filename, "w") do |f|
      add_shared_header(f)

      type_sorter.all_types.each do |weak_type|
        f << type_translator.header(weak_type) << "\n"
      end

      type_sorter.order.each do |n|
        f << type_translator.body(n) << "\n"
      end

      copy_io(@data_io, f)

      @funcs.each do |fb|
        copy_io(fb.body_io, f)
      end
    end
  end

  private def add_shared_header(io)
    io << "typedef unsigned char uint8_t;\n"
    io << "typedef unsigned short uint16_t;\n"
    io << "typedef unsigned int uint32_t;\n"
    io << "typedef unsigned long long uint64_t;\n"
    io << "typedef signed char int8_t;\n"
    io << "typedef signed short int16_t;\n"
    io << "typedef signed int int32_t;\n"
    io << "typedef signed long long int64_t;\n"
    io << "typedef unsigned long long size_t;\n"
    io << "typedef long long intptr_t;\n"
    io << "typedef unsigned long long uintptr_t;\n"
    io << "#define NULL ((void*)0)\n"
    io << "\n"

    io << "void* memcpy(void* arg0, void* arg1, uint64_t arg2);\n"
  end

  def new_func(func_def : Mod::FuncDef, header_mod : Mod) : AbstractFunc
    f = Func.new(self, func_def, header_mod)
    @funcs << f
    f
  end

  def copy_io(from : IO, to : IO)
    from.rewind
    IO.copy(from, to)
  end

  def func_head_str(name : String, type_fn : Type::Fn, static = false) : String
    String.build do |s|
      if static
        s << "static "
      end

      s << c_type(type_fn.ret)
      s << ' '
      s << name
      s << '('

      if name == "main"
        s << "int arg0, char *_arg1[]"
      else
        type_fn.args.each_with_index do |t, i|
          s << ", " if i != 0
          s << c_type(t)
          s << ' '
          s << "arg"
          s << i
        end
      end

      if type_fn.vaarg
        s << ", ..." unless type_fn.args.empty?
        s << "..." if type_fn.args.empty?
      end
      s << ')'
    end
  end
end
