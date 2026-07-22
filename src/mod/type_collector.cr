class Myc::Mod::TypeCollector
  def initialize(@typer : Typer)
  end

  def collect(mod : Mod, dom : Source::Dom)
    dom.sections.each do |section|
      case section.code
      when Opcode::Code::STRUCT
        name = get_name(section)
        check_duplicate(name, section, mod)
        type = Type::StructType.new(loc(section, mod.filename), name)
        register_type(mod, name, type, section)
      when Opcode::Code::ENUM
        name = get_name(section)
        check_duplicate(name, section, mod)
        type = Type::EnumType.new(loc(section, mod.filename), name, nil)
        register_type(mod, name, type, section)
      when Opcode::Code::FLAT
        name = get_name(section)
        check_duplicate(name, section, mod)
        type = Type::FlatType.new(loc(section, mod.filename), name)
        register_type(mod, name, type, section)
      end
    end
  end

  private def check_duplicate(name : String, node : Source::Node, mod : Mod)
    if mod.type_defs[name]?
      raise node.error("type `#{name}` already defined in this module", mod.filename)
    end

    if existing = @typer.find_in_caches(name)
      unless existing.hidden
        raise node.error("type `#{name}` already defined in another module", mod.filename)
      end
    end
  end

  private def register_type(mod : Mod, name : String, type : Type, node : Source::Node)
    @typer.map[name] = type
    mod.type_defs[name] = Mod::TypeDef.new(mod, node, type)
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
