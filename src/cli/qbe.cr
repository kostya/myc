require "./cli"
require "../backend/qbe/all"

class Myc::Cli::QBE < Myc::Cli
  private def backend_version
    ", QBE e786f06"
  end

  def cli_name
    "myc-qbe"
  end

  def dump_ext
    ".ssa"
  end
end

cli = Myc::Cli::QBE.new
cli.parse
backend = Myc::Backend::QBE::Backend.new(cli.data)
cli.catch_errors do
  backend.run
end
