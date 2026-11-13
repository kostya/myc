class Myc::Backend::GM::TypeTranslator
  getter builder : Builder
  getter typer : Typer

  def initialize(@builder, @typer)
    @cache = Hash(String, UInt64).new
  end

  def translate(type : Type) : UInt64
    @cache[type.id_name] ||= do_translate(type)
  end

  private def object_type(bytes : UInt64, align : UInt64) : UInt64
    align = 1_u64 if align == 0
    GM.ir_type(IRType::Obj) | (align.trailing_zeros_count.to_u64 << 8) | ({bytes, 1_u64}.max << 16)
  end

  private def do_translate(type : Type::VoidType)
    GM.ir_type(IRType::Void)
  end

  private def do_translate(type : Type::BoolType)
    GM.ir_type(IRType::I1)
  end

  private def do_translate(type : Type::IntType)
    case type.bytes_count
    when  8 then GM.ir_type(IRType::I64)
    when  4 then type.signed ? GM.ir_type(IRType::I32) : GM.ir_type(IRType::U32)
    when  2 then type.signed ? GM.ir_type(IRType::I16) : GM.ir_type(IRType::U16)
    when  1 then type.signed ? GM.ir_type(IRType::I8) : GM.ir_type(IRType::U8)
    when 16 then GM.ir_type(IRType::I128)
    else         GM.ir_type(IRType::I32)
    end
  end

  private def do_translate(type : Type::FloatType)
    case type.bytes_count
    when  8 then GM.ir_type(IRType::F64)
    when 16 then GM.ir_type(IRType::F80)
    else         GM.ir_type(IRType::F32)
    end
  end

  private def do_translate(type : Type::PtrType)
    GM.ir_type(IRType::Ptr)
  end

  private def do_translate(type : Type::Fn)
    GM.ir_type(IRType::Ptr)
  end

  private def do_translate(type : Type::IndirectType)
    GM.ir_type(IRType::Ptr)
  end

  private def do_translate(type : Type::VaListType)
    object_type(32_u64, 8_u64)
  end

  private def do_translate(type : Type::StructType)
    bytes = @builder.layout.size_of(type)
    bytes = 1_u64 if bytes == 0
    align = @builder.layout.alignment_of(type)
    align = 1_u64 if align < 1
    object_type(bytes, align)
  end

  private def do_translate(type : Type::FlatType)
    bytes = @builder.layout.size_of(type)
    align = @builder.layout.alignment_of(type)
    align = 1_u64 if align < 1
    object_type(bytes, align)
  end

  private def do_translate(type : Type::EnumType)
    bytes = @builder.layout.size_of(type)
    align = @builder.layout.alignment_of(type)
    align = 1_u64 if align < 1
    object_type(bytes, align)
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
