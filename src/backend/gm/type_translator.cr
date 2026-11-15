class Myc::Backend::GM::TypeTranslator
  getter builder : Builder
  getter typer : Typer

  def initialize(@builder, @typer)
    @cache = Hash(String, UInt64).new
  end

  def translate(type : Type) : UInt64
    @cache[type.id_name] ||= do_translate(type)
  end

  # A record of the fields at their layout offsets. cppgm passes and returns
  # an object of it as C passes a struct with the same fields, as QBE does
  # for its aggregate types.
  private def record(type : Type, fields : Array(LibGM::Field)) : UInt64
    bytes = {@builder.layout.size_of(type), 1_u64}.max
    align = {@builder.layout.alignment_of(type), 1_u64}.max
    @builder.record(bytes, align, fields)
  end

  # `count` elements of `type` from `offset`; none of an empty type.
  private def field(fields : Array(LibGM::Field), offset : UInt64, type : Type, count = 1_u64)
    return if count == 0 || @builder.layout.size_of(type) == 0
    fields << LibGM::Field.new(offset: offset, type: translate(type), count: count)
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
    @builder.record(32_u64, 8_u64, [LibGM::Field.new(offset: 0_u64, type: GM.ir_type(IRType::I64), count: 4_u64)])
  end

  private def do_translate(type : Type::StructType)
    fields = [] of LibGM::Field
    type.data.each_with_index do |member, index|
      field(fields, @builder.layout.field_offset(type, index.to_u64), member)
    end
    record(type, fields)
  end

  private def do_translate(type : Type::FlatType)
    fields = [] of LibGM::Field
    field(fields, 0_u64, type.target_type, type.elements_count.to_u64)
    record(type, fields)
  end

  # The tag, then the payload as an array of integers, as the C and QBE
  # backends declare an enum: the array starts at its own alignment.
  private def do_translate(type : Type::EnumType)
    fields = [] of LibGM::Field
    payload = type.payload_type.not_nil!
    offset = 0_u64
    if tag = type.index_type
      field(fields, 0_u64, tag)
      align = @builder.layout.alignment_of(payload.target_type)
      offset = (@builder.layout.size_of(tag) + align - 1) // align * align
    end
    field(fields, offset, payload.target_type, payload.elements_count.to_u64)
    record(type, fields)
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
