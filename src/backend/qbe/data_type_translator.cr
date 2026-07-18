require "./type_translator"

class Myc::Backend::QBE::DataTypeTranslator < Myc::Backend::QBE::TypeTranslator
  private def do_translate(type : Type::BoolType)
    "b"
  end

  private def do_translate(type : Type::IntType)
    case type.bytes_count
    when 8 then "l"
    when 4 then "w"
    when 2 then "h"
    when 1 then "b"
    else        "w"
    end
  end
end
