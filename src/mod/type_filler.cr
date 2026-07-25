class Myc::Mod::TypeFiller
  getter mod : Mod
  getter typer : Typer

  def initialize(@typer, @mod)
  end

  def fill(dom : Source::Dom)
    dom.sections.each do |section|
      case section.code
      when Opcode::Code::STRUCT
        name = get_name(section)
        type = mod.type_defs[name].type.as(Type::StructType)
        fill_struct(type, section.as(Source::Node::Sequence))
      when Opcode::Code::ENUM
        name = get_name(section)
        type = mod.type_defs[name].type.as(Type::EnumType)
        fill_enum(type, section.as(Source::Node::Container))
      when Opcode::Code::FLAT
        name = get_name(section)
        type = mod.type_defs[name].type.as(Type::FlatType)
        fill_flat(type, section.as(Source::Node::Sequence))
      end
    end
  end

  private def fill_struct(type : Type::StructType, node : Source::Node::Sequence)
    node.list.each do |op|
      case op.code
      when Opcode::Code::TYPE
        type.data << find_type(op)
      when Opcode::Code::ALIGN
        raise error("ALIGN already defined", op) if type.explicit_alignment
        type.explicit_alignment = get_int(op).to_u64
      else
        raise error("unexpected opcode #{op.code} in STRUCT", op)
      end
    end
  end

  private def fill_flat(type : Type::FlatType, node : Source::Node::Sequence)
    node.list.each do |op|
      case op.code
      when Opcode::Code::TYPE
        raise error("TYPE already defined", op) if type.target_type?
        type.target_type = find_type(op)
      when Opcode::Code::COUNT
        raise error("COUNT already defined", op) if type.elements_count > 0
        type.elements_count = get_int(op).to_u64
      when Opcode::Code::ALIGN
        raise error("ALIGN already defined", op) if type.explicit_alignment
        type.explicit_alignment = get_int(op).to_u64
      else
        raise error("unexpected opcode #{op.code} in FLAT", op)
      end
    end

    raise error("missing TYPE", node) unless type.target_type?
    raise error("missing COUNT", node) if type.elements_count == 0
  end

  private def fill_enum(type : Type::EnumType, node : Source::Node::Container)
    tag_type = nil
    tag_skip = false

    node.sections.each do |section|
      case section.code
      when Opcode::Code::ALIGN
        raise error("ALIGN already defined", section) if type.explicit_alignment
        type.explicit_alignment = get_int(section).to_u64
      when Opcode::Code::TAG
        section.as(Source::Node::Sequence).list.each do |op|
          case op.code
          when Opcode::Code::TYPE
            raise error("TAG already have TYPE", section) if tag_type
            tag_type = find_type(op)
          when Opcode::Code::SKIP
            raise error("TAG already skipped", section) if tag_skip
            tag_skip = true
          else
            raise error("TAG should have only TYPE or SKIP", section)
          end
        end
      when Opcode::Code::VARIANT
        variant_name = get_name(section)
        variant = Type::EnumVariantType.new(
          loc(section, mod.filename),
          type.id_name + "::" + variant_name,
          variant_name,
          type,
          type.data.size
        )
        variant.hidden = true

        section.as(Source::Node::Sequence).list.each do |op|
          case op.code
          when Opcode::Code::TYPE
            variant.value_types << find_type(op)
          else
            raise error("VARIANT should have only TYPE opcodes", section)
          end
        end

        raise error("VARIANT `#{variant_name}` already defined", section) if type.data[variant.id_name]?
        type.data[variant.id_name] = variant
        @typer.map[variant.id_name] ||= variant

        ct = Type::StructType.new(loc(section, mod.filename), variant.id_name + "::__value_type__")
        ct.hidden = true
        ct.data = variant.value_types
        variant.composite_value_type = ct
      else
        raise error("unexpected section #{section.code} in ENUM", section)
      end
    end

    if tag_type && tag_skip
      raise error("conflict TAG TYPE and SKIP", node)
    end

    type.index_type = if !tag_type && !tag_skip
                        @typer.i32
                      else
                        tag_type
                      end

    raise error("ENUM must have at least one VARIANT", node) if type.data.empty?
  end

  private def find_type(node : Source::Node) : Type
    name = get_name(node)
    @typer.find(name, Location.new(mod.filename, node.offset))
  end

  private def get_name(node : Source::Node) : String
    values = node.values
    raise error("expected name", node) unless values && values.size == 1
    case v = values.first
    when Source::Token::StringValue
      v.val
    else
      raise error("expected string value", node)
    end
  end

  private def get_int(node : Source::Node) : Int64
    values = node.values
    raise error("expected int", node) unless values && values.size == 1
    case v = values.first
    when Source::Token::IntValue
      v.val
    else
      raise error("expected int value", node)
    end
  end

  private def error(msg : String, node : Source::Node)
    node.error(msg, mod.filename)
  end

  private def loc(node : Source::Node, filename : String) : Location
    Location.new(filename, node.offset)
  end
end
