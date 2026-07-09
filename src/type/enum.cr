class Myc::Type::EnumType < Myc::Type
  property index_type : Type?
  property data = Hash(String, EnumVariantType).new
  property payload_type : FlatType?
  property explicit_alignment : UInt64?

  def initialize(@id_name, @index_type)
    @backend_name = normalize_name(id_name)
  end

  def field_type?(index : Int32) : Tuple(Int32, Type)?
    case index
    when 0
      index_type ? {0, index_type.not_nil!} : nil
    when 1
      if index_type
        payload_type ? {1, payload_type.not_nil!} : nil
      else
        payload_type ? {0, payload_type.not_nil!} : nil
      end
    end
  end

  def generate_payload_type(mod : Mod, layout : Backend::Layout)
    elements_count = layout.enum_payload_count(self)
    t = Type::FlatType.new("flat<i32, #{elements_count}>")
    t.target_type = mod.typer.i32
    t.elements_count = elements_count
    t.hidden = true
    @payload_type = t
  end
end

class Myc::Type::EnumVariantType < Myc::Type
  property original_name : String
  property parent_type : EnumType
  property position : Int32
  property value_types = Array(Type).new
  property composite_value_type : Type?

  def initialize(@id_name, @original_name, @parent_type, @position)
    @backend_name = normalize_name(id_name)
  end

  def field_type?(index : Int32) : Tuple(Int32, Type)?
    parent_type.field_type?(index)
  end
end
