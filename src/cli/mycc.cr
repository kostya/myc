require "./cli"
require "../backend/mycc/all"

class Myc::Cli::Mycc < Myc::Cli
  protected def version_string
    "myc #{VERSION}, c99-like compiler (https://github.com/kostya/myc)"
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
