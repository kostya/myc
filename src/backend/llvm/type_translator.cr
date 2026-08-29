class Myc::Backend::Llvm::TypeTranslator
  getter layout : Layout

  def initialize(@context : LLVM::Context, @layout)
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

  private def do_translate(type : Type::StructType)
    field_types = type.data.map { |t| translate(t) }
    @context.struct(field_types, type.id_name, packed: type.explicit_alignment == 1)
  end

  private def do_translate(type : Type::FlatType)
    translate(type.target_type).array(type.elements_count)
  end

  private def do_translate(type : Type::EnumType)
    _payload = type.payload_type.not_nil!
    ptype = _payload.target_type.not_nil!
    pcount = _payload.elements_count

    if index_type = type.index_type
      tag = translate(index_type)
      payload = translate(ptype).array(pcount)
      @context.struct([tag, payload], type.id_name)
    else
      payload = translate(ptype).array(pcount)
      @context.struct([payload], type.id_name)
    end
  end

  private def do_translate(type : Type::EnumVariantType)
    translate(type.parent_type)
  end

  private def do_translate(type : Type)
    raise "Unknown type: #{type.class} (#{type})"
  end
end
