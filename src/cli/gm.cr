require "./cli"
require "../backend/gm/all"

class Myc::Cli::GM < Myc::Cli
  private def backend_version
    " " + Myc::Backend::GM::Backend.version_string
  end

  def cli_name
    "myc-gm"
  end

  def dump_ext
    ".lowir"
  end
end

cli = Myc::Cli::GM.new
cli.parse
backend = Myc::Backend::GM::Backend.new(cli.data)
cli.catch_errors do
  backend.run
end
