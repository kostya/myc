require "./cli"
require "../backend/mycc/all"

class Myc::Cli::Mycc < Myc::Cli
  protected def version_string
    "mycc #{VERSION}-#{COMMIT}, c99-subset compiler (backend: #{backend_version}) (https://github.com/kostya/myc)"
  end

  private def backend_version
    backend = data.options["backend"]?.try(&.downcase.strip)
    case backend
    when "c"
      Myc::Backend::C::Backend.version_string
    when "qbe"
      Myc::Backend::QBE::Backend.version_string
    when "llvm"
      Myc::Backend::Llvm::Backend.version_string
    else
      "unknown"
    end
  end

  def cli_name
    "mycc"
  end

  def dump_ext
    ".myc"
  end

  def ext
    ".c"
  end
end

cli = Myc::Cli::Mycc.new
cli.parse
backend = Myc::Backend::Mycc::Backend.new(cli.data)
cli.catch_errors do
  backend.run
end
