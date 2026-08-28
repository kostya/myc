struct Myc::Backend::C::TypeTranslator
  getter builder : Builder

  def initialize(@builder)
    @cache = Hash(Type, String).new
  end

  def translate(type : Type) : String
    if cached = @cache[type]?
      return cached
    else
      @cache[type] = do_translate(type)
    end
  end

  private def do_translate(type : Type::VoidType) : String
    "void"
  end

  private def do_translate(type : Type::BoolType) : String
    "uint8_t"
  end

  private def do_translate(type : Type::IntType) : String
    prefix = type.signed ? "" : "u"
    case type.bytes_count
    when 8 then "#{prefix}int64_t"
    when 4 then "#{prefix}int32_t"
    when 2 then "#{prefix}int16_t"
    when 1 then "#{prefix}int8_t"
    else        "#{prefix}int32_t"
    end
  end

  private def do_translate(type : Type::FloatType) : String
    case type.bytes_count
    when 8 then "double"
    when 4 then "float"
    else        "double"
    end
  end

  private def do_translate(type : Type::Fn) : String
    @builder.type_sorter.add(type)
    "void*"
  end

  private def do_translate(type : Type::PtrType) : String
    @builder.type_sorter.add(type.target_type)
    translate(type.target_type) + "*"
  end

  private def do_translate(type : Type::StructType)
    @builder.type_sorter.add(type)
    type.backend_name
  end

  private def do_translate(type : Type::FlatType)
    @builder.type_sorter.add(type)
    type.backend_name
  end

  private def do_translate(type : Type::EnumType)
    @builder.type_sorter.add(type)
    type.backend_name
  end

  private def do_translate(type : Type::EnumVariantType)
    translate(type.parent_type)
  end

  private def do_translate(type : Type)
    raise "Unknown type: #{type.class} (#{type})"
  end

  def header(type : Type) : String
    case type
    when Type::StructType
      "typedef struct #{translate(type)} #{translate(type)};"
    when Type::EnumType
      "typedef struct #{translate(type)} #{translate(type)};"
    else
      ""
    end
  end

  def body(type : Type) : String
    case type
    when Type::StructType
      fields = type.data.each_with_index.map { |ft, i| "  #{translate(ft)} field#{i};" }.join("\n")
      "struct #{type.backend_name} {\n#{fields}\n};"
    when Type::EnumType
      fields = ""
      if type.index_type
        fields += "  #{translate(type.index_type.not_nil!)} field0;\n"
      end

      payload = type.payload_type.not_nil!
      payload_str = "  #{translate(payload)} field#{type.index_type ? "1" : "0"};\n"
      fields += payload_str

      "struct #{type.backend_name} {\n#{fields}\n};"
    when Type::FlatType
      "typedef #{translate(type.target_type)} #{type.backend_name}[#{type.elements_count}];"
    else
      ""
    end
  end
end
