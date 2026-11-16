class Myc::Backend::Llvm::TypeTranslator
  getter layout : Layout
  getter typer : Typer

  def initialize(@context : LLVM::Context, @layout, @typer)
    @cache = Hash(String, LLVM::Type).new
  end

  def translate(type : Type) : LLVM::Type
    @cache[type.id_name] ||= do_translate(type)
  end

  private def do_translate(type : Type::VoidType)
    @context.void
  end

  private def do_translate(type : Type::BoolType)
    @context.int1
  end

  private def do_translate(type : Type::IntType)
    case type.bytes_count
    when 8 then @context.int64
    when 4 then @context.int32
    when 2 then @context.int16
    when 1 then @context.int8
    else        @context.int32
    end
  end

  private def do_translate(type : Type::FloatType)
    case type.bytes_count
    when 8 then @context.double
    when 4 then @context.float
    else        @context.double
    end
  end

  private def do_translate(type : Type::PtrType)
    @context.pointer
  end

  private def do_translate(type : Type::Fn)
    @context.pointer
  end

  private def do_translate(type : Type::IndirectType)
    @context.pointer
  end

  private def do_translate(type : Type::VaListType)
    @context.pointer
  end

  private def do_translate(type : Type::StructType)
    field_types = type.data.map { |t| translate(t) }
    @context.struct(field_types, type.id_name, packed: type.explicit_alignment == 1)
  end

  private def do_translate(type : Type::FlatType)
    translate(type.target_type).array(type.elements_count)
  end

  private def do_translate(type : Type::EnumType)
    payload = translate_enum_payload(type)

    if index_type = type.index_type
      tag = translate(index_type)
      @context.struct([tag, payload], type.id_name)
    else
      @context.struct([payload], type.id_name)
    end
  end

  private def do_translate(type : Type::EnumVariantType)
    translate(type.parent_type)
  end

  private def do_translate(type : Type)
    raise "Unknown type: #{type.class} (#{type})"
  end

  private def enum_values(type : Type::EnumType) : Array(Type::StructType)
    type.data.values
      .compact_map(&.composite_value_type.as?(Type::StructType))
      .reject(&.data.empty?)
  end

  private def abi_class_of(t : Type) : Symbol
    case t
    when Type::FloatType
      :sse
    when Type::IntType, Type::BoolType, Type::PtrType
      :integer
    when Type::StructType
      t.data.reduce(:sse) do |acc, f|
        acc == :sse && abi_class_of(f) == :sse ? :sse : :integer
      end
    when Type::FlatType
      abi_class_of(t.target_type)
    else
      :integer
    end
  end

  private def abi_kind_for_values(values : Array(Type::StructType), size : UInt64) : Symbol
    return :integer if values.empty?

    return :memory if size > 16
    if values.all? { |v| v.data.all? { |f| abi_class_of(f) == :sse } }
      :sse
    else
      :integer
    end
  end

  private def translate_enum_payload(type : Type::EnumType) : LLVM::Type
    values = enum_values(type)
    size = @layout.size_of(type)
    kind = abi_kind_for_values(values, size)

    case kind
    when :sse
      payload_size = payload_size(type)
      case payload_size
      when 1..4  then @context.float
      when 5..8  then @context.double
      when 9..16 then @context.struct([@context.double, @context.double])
      else
        fallback_payload(type)
      end
    else
      fallback_payload(type)
    end
  end

  private def fallback_payload(type : Type::EnumType) : LLVM::Type
    payload = type.payload_type.not_nil!
    translate(payload.target_type).array(payload.elements_count)
  end

  private def payload_size(type : Type::EnumType) : UInt64
    full = @layout.size_of(type)
    if index_type = type.index_type
      tag_size = @layout.size_of(index_type)

      payload = type.payload_type.not_nil!
      align = @layout.alignment_of(payload.target_type)
      offset = (tag_size + align - 1) // align * align
      full - offset
    else
      full
    end
  end
end
