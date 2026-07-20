class Myc::Type::IntType < Myc::Type
  getter bytes_count : UInt64
  getter signed : Bool

  def initialize(@loc, @id_name, @bytes_count, @signed)
    @backend_name = normalize_name(id_name)
  end

  def to_unsigned : Type
    Typer::STD_TYPES["u" + id_name[1..-1]]
  end
end
