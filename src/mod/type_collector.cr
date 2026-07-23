class Myc::Mod::TypeCollector
  getter duplicates = [] of Tuple(String, Mod, Type)

  def initialize(@typer : Typer)
  end

  def collect(mod : Mod, dom : Source::Dom)
    dom.sections.each do |section|
      case section.code
      when Opcode::Code::STRUCT
        name = get_name(section)
        collect_type(name, section, mod, Type::StructType.new(loc(section, mod.filename), name))
      when Opcode::Code::ENUM
        name = get_name(section)
        collect_type(name, section, mod, Type::EnumType.new(loc(section, mod.filename), name, nil))
      when Opcode::Code::FLAT
        name = get_name(section)
        collect_type(name, section, mod, Type::FlatType.new(loc(section, mod.filename), name))
      end
    end
  end

  private def collect_type(name : String, node : Source::Node, mod : Mod, type : Type)
    if mod.type_defs[name]?
      raise node.error("type `#{name}` already defined in this module", mod.filename)
    end

    mod.type_defs[name] = Mod::TypeDef.new(mod, node, type)

    if @typer.map[name]?
      duplicates << {name, mod, type}
    else
      @typer.map[name] = type
    end
  end

  private def get_name(node : Source::Node) : String
    values = node.values
    raise "expected type name" unless values && values.size == 1
    case v = values.first
    when Source::Token::StringValue
      v.val
    else
      raise "expected string value for type name"
    end
  end

  private def loc(node : Source::Node, filename : String) : Location
    Location.new(filename, node.offset)
  end
end
