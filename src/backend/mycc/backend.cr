require "../c/all"
require "../llvm/all"
require "../qbe/all"

class Myc::Backend::Mycc::Backend < Myc::Backend::AbstractBackend
  def name
    "Mycc"
  end

  protected def ext
    ".c"
  end

  protected def filename_source?(filename : String) : Bool
    filename.ends_with?(ext) || filename.ends_with?(".myc")
  end

  def new_builder : AbstractBuilder
    raise "unreachable"
  end

  def obj(mod : Mod, output : String)
    myc_backend.obj(mod, output)
  end

  def dump(mod : Mod, output : String)
    Myc.measure("mycc_dump") do
      saver = Mod::Saver.new(mod)
      dom = saver.save
      File.open(output, "w") { |f| Myc::Source::Serialize.new(dom, f).serialize }
    end
  end

  @myc_backend : Myc::Backend::AbstractBackend?

  def myc_backend : Myc::Backend::AbstractBackend
    @myc_backend ||= begin
      name = (data.options["backend"]? || ENV["MYCC_BACKEND"]?).try(&.upcase).try(&.strip)
      unless %w{LLVM QBE C}.includes?(name)
        name = "LLVM"
      end

      puts "used #{name} backend" unless ENV["MYC_SPEC"]? == "1"

      case name
      when "LLVM"
        Myc::Backend::Llvm::Backend.new(data)
      when "C"
        Myc::Backend::C::Backend.new(data)
      when "QBE"
        Myc::Backend::QBE::Backend.new(data)
      else
        raise "unknown backend #{name}"
      end
    end
  end

  protected def validate(input : String) : Mod
    return super(input) if input.ends_with?(".myc")
    raise data.error("input not found `#{input}`") unless File.exists?(input)
    raise data.error("input not file `#{input}`") unless File.file?(input)

    Myc.debug(:mycc) do
      puts "---------------------------- Source ---------------------------------"
      puts File.read(input)
    end

    source = Myc.measure("mycc_new_source") { ::Myc::Mycc::Source.new(input) }
    tu = Myc.measure("mycc_clang_parse") { source.clang_parse }

    Myc.debug(:mycc) do
      puts "---------------------------- ClangAST ---------------------------------"
      source.debug_ast(tu.cursor)
    end

    builder = Myc.measure("mycc_new_astb") { ::Myc::Mycc::ASTBuilder.new(source, tu) }
    ast = Myc.measure("mycc_build") { builder.build }

    Myc.debug(:mycc) do
      puts "---------------------------- TypedAST ---------------------------------"
      p ast
    end

    io = Myc.measure("mycc_codegen") do
      c = ::Myc::Mycc::CodeGenerator.new(builder.mod.typer, builder)
      c.generate(ast)
    end

    Myc.debug(:mycc) do
      puts "-------------------------------------------------------------"
    end

    path = AbstractBackend.tempfile_path("mycc", "myc")
    Myc.measure("mycc_store_myc") do
      File.open(path, "w") { |f| IO.copy(io, f) }
    end
    data.files_to_cleanup << path
    super(path)
  end
end
