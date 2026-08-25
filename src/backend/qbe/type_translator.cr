class Myc::Backend::QBE::TypeTranslator
  getter builder : Builder

  def initialize(@builder)
    @cache = Hash(String, String).new
  end

  def translate(type : Type) : String
    @cache[type.id_name] ||= do_translate(type)
  end

  private def do_translate(type : Type::VoidType)
    ""
  end

  private def do_translate(type : Type::BoolType)
    "w"
  end

  private def do_translate(type : Type::IntType)
    case type.bytes_count
    when 8 then "l"
    else        "w"
    end
  end

  private def do_translate(type : Type::FloatType)
    case type.bytes_count
    when 8 then "d"
    else        "s"
    end
  end

  private def do_translate(type : Type::PtrType)
    "l"
  end

  private def do_translate(type : Type::Fn)
    "l"
  end

  private def do_translate(type : Type::StructType)
    name = ":" + type.backend_name
    fields = type.data.map { |t| translate(t) }.join(", ")
    @builder.emit_type("type #{name} = { #{fields} }\n")
    name
  end

  private def do_translate(type : Type::FlatType)
    name = ":" + type.backend_name
    elem_type = translate(type.target_type)
    @builder.emit_type("type #{name} = { #{elem_type} #{type.elements_count} }\n")
    name
  end

  private def do_translate(type : Type::EnumType)
    _payload = type.payload_type.not_nil!
    ptype = _payload.target_type.not_nil!
    pcount = _payload.elements_count

    name = ":" + type.backend_name
    if index_type = type.index_type
      tag_type = translate(index_type)
      if pcount > 0
        ptype_s = translate(ptype)
        @builder.emit_type("type #{name} = { #{tag_type}, #{ptype_s} #{pcount} }\n")
      else
        @builder.emit_type("type #{name} = { #{tag_type} }\n")
      end
    else
      if pcount > 0
        ptype_s = translate(ptype)
        @builder.emit_type("type #{name} = { #{ptype_s} #{pcount} }\n")
      else
        @builder.emit_type("type #{name} = { }\n")
      end
    end
    name
  end

  private def do_translate(type : Type::EnumVariantType)
    translate(type.parent_type)
  end

  private def do_translate(type : Type)
    raise "Unknown type: #{type.class} (#{type})"
  end
end
