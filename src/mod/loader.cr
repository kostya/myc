class Myc::Mod::Loader
  def initialize(@dom : Source::Dom, @filename : String, @typer : Typer, @mod : Mod)
  end

  def load
    @dom.sections.each do |section|
      case section.code
      when Opcode::Code::FUNC
        func = load_func(section.as(Source::Node::Container))
        @mod.func_defs[func.name] = func
      when Opcode::Code::GLOBAL
        load_global(section.as(Source::Node::Sequence))
      when Opcode::Code::STRUCT, Opcode::Code::ENUM, Opcode::Code::FLAT
      else
        raise error("unexpected section #{section.code}", section)
      end
    end
  end

  private def error(msg : String, node : Source::Node)
    node.error(msg, @mod.filename)
  end

  private def expect_zero_values(node)
    values = node.values
    raise error("#{node.code} expected zero values, but got #{values.inspect}", node) unless !values || values.size == 0
  end

  private def get_only_one_string_value(node) : String
    values = node.values
    raise error("#{node.code} expected only 1 value", node) if !values || values.size != 1
    case v = values.first
    when Source::Token::StringValue
      return v.val
    else
      raise error("#{node.code} expect string value, not #{v.inspect}", node)
    end
  end

  private def get_string_value(node, value) : String
    case v = value
    when Source::Token::StringValue
      return v.val
    else
      raise error("#{node.code} expect string value, not #{value.inspect}", node)
    end
  end

  private def get_int_value(node, value) : Int
    case v = value
    when Source::Token::IntValue
      return v.val
    else
      raise error("#{node.code} expect Int value, not #{value.inspect}", node)
    end
  end

  private def get_only_one_int_value(node) : Int
    values = node.values
    raise error("#{node.code} expected only 1 value", node) if !values || values.size != 1
    case v = values.first
    when Source::Token::IntValue
      return v.val
    else
      raise error("#{node.code} expect int value, not #{v.inspect}", node)
    end
  end

  private def get_only_two_string_values(node) : Tuple(String, String)
    values = node.values
    raise error("#{node.code} expected only 2 value", node) if !values || values.size != 2
    case v = values.first
    when Source::Token::StringValue
      case v2 = values[1]
      when Source::Token::StringValue
        {v.val, v2.val}
      else
        raise error("#{node.code} expect second string value, not #{v2.inspect}", node)
      end
    else
      raise error("#{node.code} expect first string value, not #{v.inspect}", node)
    end
  end

  private def load_func(node : Source::Node::Container) : Mod::FuncDef
    func_name = get_only_one_string_value(node)
    ret_type = nil
    arg_types = [] of Type
    body_node = nil
    attributes = nil

    node.sections.each do |section|
      case section.code
      when Opcode::Code::RETURN
        raise error("return already defined", section) if ret_type
        tl = extract_types_list(section.as(Source::Node::Sequence))
        raise error("return should have one type", section) if tl.size != 1
        ret_type = tl[0]
      when Opcode::Code::ARGS
        raise error("args already defined", section) if arg_types.present?
        arg_types = extract_types_list(section.as(Source::Node::Sequence))
      when Opcode::Code::BODY
        raise error("body already defined", section) if body_node
        body_node = section.as(Source::Node::Sequence)
      when Opcode::Code::ATTRIBUTES
        raise error("ATTRIBUTES already defined", section) if attributes
        attributes = extract_attributes_list(section.as(Source::Node::Sequence))
      else
        raise error("unexpected section #{section.code}", section)
      end
    end

    type_fn = Type::Fn.new(loc(node), arg_types, ret_type || @mod.typer.void, !!attributes.try(&.includes?("vaarg")))
    if t = @mod.typer.map[type_fn.id_name]?
      type_fn = t.as(Type::Fn)
    else
      @mod.typer.map[type_fn.id_name] = type_fn
    end
    func = Mod::FuncDef.new(node, @mod, func_name, type_fn, attributes)

    if body = body_node
      func.body = load_seq(body, func)
      func.inline_stats.finish(func)
    end

    func
  end

  private def load_seq(node : Source::Node::Sequence, func_def : Mod::FuncDef) : Opcode::Seq
    seq = Opcode::Seq.new.with_position(node)
    node.list.each do |op_node|
      seq.list << load_opcode(op_node, func_def)
    end
    seq
  end

  private def load_opcode(node : Source::Node, func_def : FuncDef) : Opcode
    op = _load_opcode(node, func_def)
    func_def.inline_stats.update(op)
    op
  end

  private def _load_opcode(node : Source::Node, func_def : FuncDef) : Opcode
    case node.code
    when Opcode::Code::AS
      Opcode::As.new(find_type(get_only_one_string_value(node), node)).with_position(node)
    when Opcode::Code::BINARY
      op_name = get_only_one_string_value(node)
      op = Opcode::Binary::Op.parse?(op_name) || raise error("unknown op #{op_name}", node)
      Opcode::Binary.new(op).with_position(node)
    when Opcode::Code::BREAK
      expect_zero_values(node)
      Opcode::Break.new.with_position(node)
    when Opcode::Code::CALL
      values = node.values
      raise error("#{node.code} should have at least 1 value", node) unless values
      case values.size
      when 1
        Opcode::Call.new(get_string_value(node, values.first)).with_position(node)
      when 2
        Opcode::Call.new(get_string_value(node, values.first), get_int_value(node, values[1]).to_i32).with_position(node)
      else
        raise error("#{node.code} expected 1 or 2 values", node)
      end
    when Opcode::Code::INVOKE
      if values = node.values
        Opcode::Invoke.new(get_only_one_int_value(node).to_i32).with_position(node)
      else
        Opcode::Invoke.new.with_position(node)
      end
    when Opcode::Code::FIELD
      Opcode::Field.new(get_only_one_int_value(node).to_i32).with_position(node)
    when Opcode::Code::GLOBAL
      Opcode::Global.new(get_only_one_string_value(node)).with_position(node)
    when Opcode::Code::IF
      load_if(node, func_def)
    when Opcode::Code::INSPECT
      expect_zero_values(node)
      Opcode::Inspect.new.with_position(node)
    when Opcode::Code::LOCAL
      values = node.values
      raise error("#{node.code} should have at least 1 value", node) unless values
      case values.size
      when 1
        Opcode::Local.new(get_string_value(node, values.first)).with_position(node)
      when 2
        Opcode::Local.new(get_string_value(node, values.first), find_type(get_string_value(node, values[1]), node)).with_position(node)
      else
        raise error("#{node.code} expected 1 or 2 values", node)
      end
    when Opcode::Code::LOOP
      load_loop(node, func_def)
    when Opcode::Code::ALLOCA
      Opcode::Alloca.new(find_type(get_only_one_string_value(node), node)).with_position(node)
    when Opcode::Code::MALLOC
      Opcode::Malloc.new(find_type(get_only_one_string_value(node), node)).with_position(node)
    when Opcode::Code::SIZEOF
      if values = node.values
        Opcode::SizeOf.new(find_type(get_only_one_string_value(node), node)).with_position(node)
      else
        Opcode::SizeOf.new.with_position(node)
      end
    when Opcode::Code::NEXT
      expect_zero_values(node)
      Opcode::Next.new.with_position(node)
    when Opcode::Code::PARAM
      Opcode::Param.new(get_only_one_int_value(node).to_i32).with_position(node)
    when Opcode::Code::PRINTF
      Opcode::Printf.new(get_only_one_int_value(node).to_i32).with_position(node)
    when Opcode::Code::DEREF
      expect_zero_values(node)
      Opcode::Deref.new.with_position(node)
    when Opcode::Code::PUSH
      values = node.values
      raise error("#{node.code} should have at least 1 value", node) unless values
      case values.size
      when 1
        Opcode::Push.new(values.first).with_position(node)
      when 2
        Opcode::Push.new(values.first, find_type(get_string_value(node, values[1]), node)).with_position(node)
      else
        raise error("#{node.code} expected 1 or 2 values", node)
      end
    when Opcode::Code::RET
      expect_zero_values(node)
      Opcode::Ret.new.with_position(node)
    when Opcode::Code::STORE
      expect_zero_values(node)
      Opcode::Store.new.with_position(node)
    when Opcode::Code::SWITCH
      load_switch(node, func_def)
    when Opcode::Code::UNARY
      op_name = get_only_one_string_value(node)
      op = Opcode::Unary::Op.parse?(op_name) || raise error("unknown op #{op_name}", node)
      Opcode::Unary.new(op).with_position(node)
    when Opcode::Code::STACK
      values = node.values
      raise error("#{node.code} should have at least 1 value", node) unless values
      case values.size
      when 1
        op_name = get_only_one_string_value(node)
        op = Opcode::Stack::Shift.parse?(op_name) || raise error("unknown shift #{op_name}", node)
        Opcode::Stack.new(op).with_position(node)
      when 2
        op_name = get_string_value(node, values[0])
        op = Opcode::Stack::Shift.parse?(op_name) || raise error("unknown shift #{op_name}", node)
        val = get_int_value(node, values[1])
        Opcode::Stack.new(op, val).with_position(node)
      else
        raise error("#{node.code} expected 1 or 2 values", node)
      end
    when Opcode::Code::SELECT
      expect_zero_values(node)
      Opcode::Select.new.with_position(node)
    when Opcode::Code::CREATE
      Opcode::Create.new(find_type(get_only_one_string_value(node), node)).with_position(node)
    when Opcode::Code::ADDR
      if values = node.values
        Opcode::Addr.new(get_only_one_string_value(node)).with_position(node)
      else
        Opcode::Addr.new.with_position(node)
      end
    when Opcode::Code::TO
      Opcode::To.new(find_type(get_only_one_string_value(node), node)).with_position(node)
    when Opcode::Code::GOTO
      Opcode::Goto.new(get_only_one_string_value(node)).with_position(node)
    when Opcode::Code::LABEL
      Opcode::Label.new(get_only_one_string_value(node)).with_position(node)
    when Opcode::Code::SLOT
      Opcode::Slot.new(get_only_one_string_value(node)).with_position(node)
    else
      raise error("unknown opcode #{node.code}", node)
    end
  end

  private def load_if(node, func_def : FuncDef) : Opcode::If
    expect_zero_values(node)
    then_seq = nil
    else_seq = nil

    node.as(Source::Node::Container).sections.each do |section|
      case section.code
      when Opcode::Code::THEN
        raise error("then already defined", section) if then_seq
        then_seq = load_seq(section.as(Source::Node::Sequence), func_def)
      when Opcode::Code::ELSE
        raise error("else already defined", section) if else_seq
        else_seq = load_seq(section.as(Source::Node::Sequence), func_def)
      else
        raise error("unknown section #{section.code}", section)
      end
    end

    if then_seq
      Opcode::If.new(then_seq, else_seq || Opcode::Seq.new).with_position(node)
    else
      raise error("undefined THEN section", node)
    end
  end

  private def load_loop(node, func_def : FuncDef) : Opcode::Loop
    expect_zero_values(node)

    init_seq = nil
    cond_seq = nil
    body_seq = nil
    step_seq = nil

    node.as(Source::Node::Container).sections.each do |section|
      case section.code
      when Opcode::Code::INIT
        raise error("INIT already defined", section) if init_seq
        init_seq = load_seq(section.as(Source::Node::Sequence), func_def)
      when Opcode::Code::COND
        raise error("COND already defined", section) if cond_seq
        cond_seq = load_seq(section.as(Source::Node::Sequence), func_def)
      when Opcode::Code::BODY
        raise error("BODY already defined", section) if body_seq
        body_seq = load_seq(section.as(Source::Node::Sequence), func_def)
      when Opcode::Code::STEP
        raise error("STEP already defined", section) if step_seq
        step_seq = load_seq(section.as(Source::Node::Sequence), func_def)
      else
        raise error("unknown section #{section.code}", section)
      end
    end

    if body_seq
      init_seq ||= Opcode::Seq.new
      cond_seq ||= Opcode::Seq.new
      cond_seq.stack_balance = 1
      step_seq ||= Opcode::Seq.new
      Opcode::Loop.new(init_seq, cond_seq, body_seq, step_seq).with_position(node)
    else
      raise error("LOOP should have at least BODY", node)
    end
  end

  private def load_switch(node, func_def : FuncDef) : Opcode::Switch
    expect_zero_values(node)

    cases_seq = Array(Opcode::Seq).new
    values = Array(Int64).new
    else_seq = nil

    node.as(Source::Node::Container).sections.each do |section|
      case section.code
      when Opcode::Code::CASE
        values << get_only_one_int_value(section)
        cases_seq << load_seq(section.as(Source::Node::Sequence), func_def)
      when Opcode::Code::ELSE
        raise error("ELSE already defined", section) if else_seq
        else_seq = load_seq(section.as(Source::Node::Sequence), func_def)
      else
        raise error("unknown section #{section.code}", section)
      end
    end

    if cases_seq.size != values.size
      raise error("#{cases_seq.size} != #{values.size}", node)
    end

    if cases_seq.size > 0
      Opcode::Switch.new(cases_seq, values, else_seq || Opcode::Seq.new).with_position(node)
    else
      raise error("SWITCH empty cases", node)
    end
  end

  private def extract_types_list(node : Source::Node::Sequence) : Array(Type)
    node.list.map do |op|
      case op.code
      when Opcode::Code::TYPE
        find_type(get_only_one_string_value(op), op)
      else
        raise error("expected type", op)
      end
    end
  end

  private def extract_attributes_list(node : Source::Node::Sequence) : Array(String)
    node.list.map do |op|
      case op.code
      when Opcode::Code::ATTR
        get_only_one_string_value(op)
      else
        raise error("expected type", op)
      end
    end
  end

  private def load_global(node : Source::Node::Sequence)
    global_name = get_only_one_string_value(node)

    global_type = nil
    init_values = nil
    constant_flag = false
    initial_keyword = false
    global_private = false

    node.list.each do |op|
      case op.code
      when Opcode::Code::TYPE
        raise error("TYPE already defined for GLOBAL #{global_name}", op) if global_type
        global_type = find_type(get_only_one_string_value(op), op)
      when Opcode::Code::INITIAL
        raise error("INITIAL already defined for GLOBAL #{global_name}", op) if init_values
        init_values = op.values
        initial_keyword = true
      when Opcode::Code::CONSTANT
        raise error("CONSTANT already defined for GLOBAL", op) if constant_flag
        values = op.values
        raise error("CONSTANT have no values", op) if values && values.size > 0
        constant_flag = true
      when Opcode::Code::PRIVATE
        global_private = true
      else
        raise error("unexpected opcode #{op.code} in GLOBALDEF", op)
      end
    end

    raise error("missing TYPE for GLOBALDEF #{global_name}", node) unless global_type

    init_values ||= Array(Source::Token::Value).new
    @mod.global_defs[global_name] = Mod::GlobalDef.new(@mod, node, global_name, global_type, initial_keyword, init_values, constant_flag, global_private)
  end

  private def find_type(name : String, node : Source::Node) : Type
    @mod.typer.find(name, Location.new(@mod.filename, node.offset))
  end

  private def loc(node : Source::Node) : Location
    Location.new(@mod.filename, node.offset)
  end
end
