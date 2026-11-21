require "../c/all"
require "../llvm/all"
require "../qbe/all"
require "../gm/all"

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

  def obj(mod : Mod, header_mod : Mod, output : String)
    puts "used #{get_backend_string? || "LLVM"} backend" unless ENV["MYC_SPEC"]? == "1"
    myc_backend.obj(mod, header_mod, output)
  end

  def dump(mod : Mod, header_mod : Mod, output : String)
    Myc.measure("mycc:dump") do
      if get_backend_string?
        myc_backend.dump(mod, header_mod, output)
      else
        saver = Mod::Saver.new(mod)
        dom = saver.save
        File.open(output, "w") { |f| IO.copy(dom.serialize, f) }
      end
    end
  end

  @myc_backend : Myc::Backend::AbstractBackend?

  def myc_backend : Myc::Backend::AbstractBackend
    @myc_backend ||= begin
      name = get_backend_string? || "LLVM"

      backend = case name
                when "LLVM"
                  Myc::Backend::Llvm::Backend.new(data)
                when "C"
                  Myc::Backend::C::Backend.new(data)
                when "QBE"
                  Myc::Backend::QBE::Backend.new(data)
                when "GM"
                  Myc::Backend::GM::Backend.new(data)
                else
                  raise "unknown backend #{name}"
                end
      backend.typer = @typer
      backend
    end
  end

  protected def parse_file(input : String) : LoadMod
    if input.ends_with?(".myc")
      super
    else
      mod = Mod.new(File.basename(input, ext), input, @typer)
      LoadMod.new(mod)
    end
  end

  protected def load_mod(l : LoadMod)
    return super if l.mod.filename.ends_with?(".myc")

    Myc.debug(:mycc) do
      puts "---------------------------- Source ---------------------------------"
      puts File.read(l.mod.filename)
    end

    source = Myc.measure("mycc:new_source") { ::Myc::Mycc::CSource.new(l.mod.filename) }
    tu = Myc.measure("mycc:clang_parse") { source.clang_parse }

    Myc.debug(:mycc) do
      puts "---------------------------- ClangAST ---------------------------------"
      source.debug_ast(tu.cursor)
    end

    builder = Myc.measure("mycc:new_astb") { ::Myc::Mycc::ASTBuilder.new(source, tu, typer, shared_types) }
    ast = Myc.measure("mycc:astb_build") { builder.build }

    Myc.debug(:mycc) do
      puts "---------------------------- TypedAST ---------------------------------"
      p ast
    end

    Myc.measure("mycc:finalize_enums") do
      builder.mod.finalize_enums(new_layout)
    end

    Myc.measure("mycc:codegen") do
      c = ::Myc::Mycc::CodeGenerator.new(builder.mod.typer, builder, l.mod)
      c.generate(ast)
    end

    Myc.debug(:mycc) do
      puts "---------------------------- MYC ---------------------------------"
      saver = Mod::Saver.new(l.mod)
      dom = saver.save
      IO.copy(dom.serialize, STDOUT)
    end

    Myc.debug(:mycc) do
      puts "-------------------------------------------------------------"
    end
  end

  protected def resolve_input(input : String) : String
    return input if input.ends_with?(".myc")

    raise data.error("unexpected file extension `#{input}`, expected #{ext}") unless input.ends_with?(ext)

    raise data.error("input not found `#{input}`") unless File.exists?(input)
    raise data.error("input not file `#{input}`") unless File.file?(input)

    input
  end

  @shared_types : SharedTypes?

  def shared_types
    @shared_types ||= SharedTypes.new(typer)
  end

  private def get_backend_string? : String?
    name = (data.options["backend"]? || ENV["MYCC_BACKEND"]?).try(&.upcase).try(&.strip)
    if %w{LLVM QBE C GM}.includes?(name)
      name
    end
  end

  protected def additional_linker_flags : Array(String)
    myc_backend.additional_linker_flags
  end
end
