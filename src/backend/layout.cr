class Myc::Backend::Layout
  getter target : Target

  def initialize(@target)
    @size_cache = Hash(Type, UInt64).new
    @alignment_cache = Hash(Type, UInt64).new
  end

  def size_of(type : Type) : UInt64
    @size_cache[type] ||= _size_of(type)
  end

  def alignment_of(type : Type) : UInt64
    @alignment_cache[type] ||= _alignment_of(type)
  end

  private def _size_of(type : Type) : UInt64
    case type
    when Type::IntType         then type.bytes_count
    when Type::FloatType       then type.bytes_count
    when Type::PtrType         then @target.pointer_size
    when Type::BoolType        then 1_u64
    when Type::VoidType        then 0_u64
    when Type::StructType      then compute_struct_size(type)
    when Type::FlatType        then type.elements_count * size_of(type.target_type)
    when Type::EnumType        then compute_enum_size(type)
    when Type::EnumVariantType then compute_enum_size(type.parent_type)
    when Type::Fn              then @target.pointer_size
    else                            raise "unexpected type #{type.inspect}"
    end
  end

  private def _alignment_of(type : Type) : UInt64
    case type
    when Type::IntType         then type.bytes_count
    when Type::FloatType       then type.bytes_count
    when Type::PtrType         then @target.pointer_alignment
    when Type::BoolType        then 1_u64
    when Type::StructType      then compute_struct_alignment(type)
    when Type::FlatType        then alignment_of(type.target_type)
    when Type::EnumType        then compute_enum_alignment(type)
    when Type::EnumVariantType then compute_enum_alignment(type.parent_type)
    when Type::Fn              then @target.pointer_alignment
    else                            raise "unexpected type #{type.inspect}"
    end
  end

  private def compute_struct_size(type : Type::StructType) : UInt64
    offset = 0_u64
    struct_alignment = type.explicit_alignment

    type.data.each do |field_type|
      align = struct_alignment || alignment_of(field_type)
      offset = align_to(offset, align)
      offset += size_of(field_type)
    end

    final_alignment = struct_alignment ||
                      (type.data.any? ? type.data.max_of { |t| alignment_of(t) } : 1_u64)
    align_to(offset, final_alignment)
  end

  private def compute_struct_alignment(type : Type::StructType) : UInt64
    if ea = type.explicit_alignment
      return ea
    end

    if type.data.any?
      return type.data.max_of { |t| alignment_of(t) }
    end

    1_u64
  end

  def field_offset(type : Type::StructType, index : UInt64) : UInt64
    offset = 0_u64
    return offset if index == 0

    struct_alignment = type.explicit_alignment

    0.upto(index - 1) do |i|
      field = type.data[i]

      align = struct_alignment || alignment_of(field)
      offset = align_to(offset, align)
      offset += size_of(field)
    end

    field = type.data[index]
    align = struct_alignment || alignment_of(field)
    align_to(offset, align)
  end

  def field_offset(type : Type::FlatType, index : UInt64) : UInt64
    size_of(type.target_type) * index
  end

  def field_offset(type : Type::EnumType, index : UInt64) : UInt64
    case index
    when 0
      0_u64
    when 1
      if index_type = type.index_type
        tag_size = size_of(index_type)
        tag_align = alignment_of(index_type)
        align_to(tag_size, tag_align)
      else
        0_u64
      end
    else
      raise "enum #{type.id_name} has no field #{index}"
    end
  end

  def field_offset(type : Type::EnumVariantType, index : UInt64) : UInt64
    field_offset(type.parent_type, index)
  end

  def field_offset(type : Type, index : UInt64) : UInt64
    raise "undefined field_offset for #{type}"
  end

  private def align_to(offset : UInt64, alignment : UInt64) : UInt64
    (offset + alignment - 1) // alignment * alignment
  end

  private def compute_enum_size(type : Type::EnumType) : UInt64
    tag_size = 0_u64
    tag_align = 0_u64

    if index_type = type.index_type
      tag_size = size_of(index_type)
      tag_align = alignment_of(index_type)
    end

    max_payload = if type.data.any?
                    type.data.max_of do |_, variant|
                      if cvt = variant.composite_value_type
                        size_of(cvt)
                      else
                        0_u64
                      end
                    end
                  else
                    0_u64
                  end

    total = (tag_size > 0 ? align_to(tag_size, tag_align) : tag_size) + max_payload
    align_to(total, compute_enum_alignment(type))
  end

  private def compute_enum_alignment(type : Type::EnumType) : UInt64
    if ea = type.explicit_alignment
      return ea
    end

    tag_align = type.index_type ? alignment_of(type.index_type.not_nil!) : 0_u64

    max_payload = if type.data.any?
                    type.data.max_of do |_, variant|
                      if cvt = variant.composite_value_type
                        alignment_of(cvt)
                      else
                        0_u64
                      end
                    end
                  else
                    0_u64
                  end

    {tag_align, max_payload, 1_u64}.max
  end

  def enum_payload_info(type : Type::EnumType) : Tuple(UInt64, UInt64)
    alignment = alignment_of(type)
    payload_size = size_of(type) - (type.index_type ? align_to(size_of(type.index_type.not_nil!), alignment) : 0_u64)
    {alignment, payload_size > 0 ? (payload_size + (alignment - 1)) // alignment : 0_u64}
  end

  def ptr_as_int_type(typer : Typer) : Type::IntType
    target.pointer_size == 8 ? typer.u64.as(Type::IntType) : typer.u32.as(Type::IntType)
  end

  def int_format(type : Type::IntType) : String
    if type.signed
      case type.bytes_count
      when 8 then "%lli"
      when 4 then "%d"
      when 2 then "%hi"
      else        "%hhi"
      end
    else
      case type.bytes_count
      when 8 then "%llu"
      when 4 then "%u"
      when 2 then "%hu"
      else        "%hhu"
      end
    end
  end

  def int_hex_format(type : Type::IntType) : String
    case type.bytes_count
    when 8 then "0x%llx"
    when 4 then "0x%x"
    when 2 then "0x%hx"
    else        "0x%hhx"
    end
  end

  def float_format(type : Type::FloatType) : String
    "%.7f"
  end
end
