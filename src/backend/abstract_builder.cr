abstract class Myc::Backend::AbstractBuilder
  getter backend : AbstractBackend
  getter layout : Layout
  getter std_funcs : Hash(String, Type::Fn)
  getter inspect_funcs : Hash(Type, String)
  getter inspect_type_fns : Hash(String, Type::Fn)

  def initialize(@backend, @layout)
    @std_funcs = add_std_funcs
    @inspect_funcs = Hash(Type, String).new
    @inspect_type_fns = Hash(String, Type::Fn).new
  end

  def add_std_funcs
    void = Mod::Typer::STD_TYPES["void"]
    i32 = Mod::Typer::STD_TYPES["i32"]
    u32 = Mod::Typer::STD_TYPES["u32"]

    u64 = Mod::Typer::STD_TYPES["u64"]

    u8p = Mod::Typer::STD_TYPES["ptr<u8>"]
    voidp = Mod::Typer::STD_TYPES["ptr<void>"]

    f32 = Mod::Typer::STD_TYPES["f32"]
    f64 = Mod::Typer::STD_TYPES["f64"]

    h = Hash(String, Type::Fn).new

    h["printf"] = Type::Fn.new([u8p], i32, vaarg: true)

    h["malloc"] = Type::Fn.new([u64], voidp)
    h["calloc"] = Type::Fn.new([u64, u64], voidp)

    h["free"] = Type::Fn.new([voidp], void)

    h
  end

  abstract def constant_value?(value : Source::Token::ArgType, type : Type) : Value?
  abstract def find_global(name : String) : Value?
  abstract def new_func(func_def : Mod::FuncDef) : AbstractFunc
  abstract def func_register(name : String, type_fn : Type::Fn)

  protected def escaped_string(s : String)
    s.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
  end
end
