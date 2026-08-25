class Myc::Type::EnumType < Myc::Type
  property index_type : Type?
  property data = Hash(String, EnumVariantType).new
  property payload_type : FlatType?
  property explicit_alignment : UInt64?

  def initialize(@loc, @id_name, @index_type)
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
    alignment, elements_count = layout.enum_payload_info(self)

    flat_element_type = case alignment
                        when 1
                          mod.typer.i8
                        when 2
                          mod.typer.i16
                        when 4
                          mod.typer.i32
                        when 8
                          mod.typer.i64
                        else
                          raise Error::ErrorLoc.new("Bad enum alignment #{alignment}, bug", loc)
                        end

    t = Type::FlatType.new(loc, "flat<#{flat_element_type.id_name}, #{elements_count}>")
    t.target_type = flat_element_type
    t.elements_count = elements_count
    t.hidden = true
    @payload_type = t
  end

  def flat_elements_count : UInt64
    res = 0_u64
    if t = index_type
      res += t.flat_elements_count
    end
    if pt = payload_type
      res += pt.flat_elements_count
    end
    res
  end
end

class Myc::Type::EnumVariantType < Myc::Type
  property original_name : String
  property parent_type : EnumType
  property position : Int32
  property value_types = Array(Type).new
  property composite_value_type : Type?

  def initialize(@loc, @id_name, @original_name, @parent_type, @position)
    @backend_name = normalize_name(id_name)
  end

  def field_type?(index : Int32) : Tuple(Int32, Type)?
    parent_type.field_type?(index)
  end

  def flat_elements_count : UInt64
    parent_type.flat_elements_count
  end
end
