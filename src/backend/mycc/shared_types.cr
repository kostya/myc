class Myc::Backend::Mycc::SharedTypes
  getter typer : Typer
  getter struct_fields

  def initialize(@typer)
    @struct_fields = Hash(String, Array({String, Myc::Type})).new
  end
end
