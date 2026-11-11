class Myc::Backend::GM::TypeTranslator
  getter builder : Builder
  getter typer : Typer

  def initialize(@builder, @typer)
    @cache = Hash(String, String).new
  end

  def translate(type : Type) : String
    @cache[type.id_name] ||= do_translate(type)
  end

  private def do_translate(type : Type::VoidType)
    "void"
  end

  private def do_translate(type : Type::BoolType)
    "i1"
  end

  private def do_translate(type : Type::IntType)
    case type.bytes_count
    when  8 then "i64"
    when  4 then type.signed ? "i32" : "u32"
    when  2 then type.signed ? "i16" : "u16"
    when  1 then type.signed ? "i8" : "u8"
    when 16 then "i128"
    else         "i32"
    end
  end

  private def do_translate(type : Type::FloatType)
    case type.bytes_count
    when  8 then "f64"
    when 16 then "f80"
    else         "f32"
    end
  end

  private def do_translate(type : Type::PtrType)
    "ptr"
  end

  private def do_translate(type : Type::Fn)
    "ptr"
  end

  private def do_translate(type : Type::IndirectType)
    "ptr"
  end

  private def do_translate(type : Type::VaListType)
    "obj<32x8>"
  end

  private def do_translate(type : Type::StructType)
    bytes = @builder.layout.size_of(type)
    bytes = 1 if bytes == 0
    align = @builder.layout.alignment_of(type)
    align = 1 if align < 1
    "obj<#{bytes}x#{align}>"
  end

  private def do_translate(type : Type::FlatType)
    bytes = @builder.layout.size_of(type)
    align = @builder.layout.alignment_of(type)
    align = 1 if align < 1
    "obj<#{bytes}x#{align}>"
  end

  private def do_translate(type : Type::EnumType)
    bytes = @builder.layout.size_of(type)
    align = @builder.layout.alignment_of(type)
    align = 1 if align < 1
    "obj<#{bytes}x#{align}>"
  end

  private def do_translate(type : Type::EnumVariantType)
    translate(type.parent_type)
  end

  private def do_translate(type : Type)
    raise "Unknown type: #{type.class} (#{type})"
  end
end

class Myc::Backend::GM::DataTypeTranslator < Myc::Backend::GM::TypeTranslator
end
