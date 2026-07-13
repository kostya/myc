require "./cli"
require "../backend/llvm/all"

class Myc::Cli::Llvm < Myc::Cli
  private def backend_version
    ", " + Myc::Backend::Llvm::Backend.version_string
  end

  def cli_name
    "myc-llvm"
  end

  def dump_ext
    ".ll"
  end
end

cli = Myc::Cli::Llvm.new
cli.parse
backend = Myc::Backend::Llvm::Backend.new(cli.data)
cli.catch_errors do
  backend.run
end
