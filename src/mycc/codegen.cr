class Myc::Mycc::CodeGenerator
  getter typer : Typer
  getter builder : ASTBuilder
  getter mod : Mod

  class VarInfo
    getter type : Type
    getter is_static : Bool
    getter unique_name : String?
    getter mangled_name : String
    getter var_decl : TypedAST::VarDecl?

    def initialize(@type, @mangled_name, @is_static = false, @unique_name = nil, @var_decl : TypedAST::VarDecl? = nil)
    end
  end

  @current_function : TypedAST::Function?

  def initialize(@typer, @builder, @mod)
    @vars_stack = [Hash(String, VarInfo).new]
    @params = Hash(String, Int32).new
    @globals = Hash(Tuple(String, String), TypedAST::VarDecl).new
    @local_marks = Set(String).new
    @switch_count = 0
    @scope_counter = 0
    @temp_counter = 0_u64
    @current_function_name = ""
    @current_function = nil
    @seq = Opcode::Seq.new
  end

  def current_vars : Hash(String, VarInfo)
    @vars_stack.last
  end

  def find_var(name : String) : VarInfo?
    @vars_stack.reverse_each do |scope|
      if v = scope[name]?
        return v
      end
    end
    nil
  end

  def push_scope
    @vars_stack.push(Hash(String, VarInfo).new)
    @scope_counter += 1
  end

  def pop_scope
    @vars_stack.pop
  end

  def mangled_name(name : String) : String
    "__s#{@scope_counter}_#{name}"
  end

  def generate(program : TypedAST::Program)
    program.globals.each do |var|
      node = Source::Node.new(Opcode::Code::GLOBAL)
      values = Array(Source::Token::Value).new
      if init = var.init
        emit_init_element(values, init, var.func_name)
      end
      gdef = Mod::GlobalDef.new(mod, node, var.global_name, var.var_type, !!var.init, values, false, var.is_static)
      mod.global_defs[var.global_name] = gdef
      @globals[{var.func_name, var.name}] = var
    end

    program.functions.each_value { |f| generate_function(f) }
  end

  private def emit_init_element(values : Array(Source::Token::Value), elem : TypedAST::Node, func_name : String)
    case elem
    when TypedAST::IntLiteral
      values << Source::Token::IntValue.new(elem.value)
    when TypedAST::CharLiteral
      values << Source::Token::IntValue.new(elem.value)
    when TypedAST::FloatLiteral
      values << Source::Token::FloatValue.new(elem.value)
    when TypedAST::StringLiteral
      if elem.type.is_a?(Type::PtrType)
        values << Source::Token::StringValue.new(elem.value)
        return
      end
      value = elem.value
      str = String.build do |s|
        i = 0
        value.each_byte do |b|
          s << ' ' if i != 0
          s << b
          i += 1
        end
        s << " 0"
      end
      values << Source::Token::StringValue.new(str)
    when TypedAST::Cast
      emit_init_element(values, elem.operand, func_name)
    when TypedAST::ZeroInitializer
      elem.type.flat_elements_count.times do
        values << Source::Token::IntValue.new(0_u64)
      end
    when TypedAST::InitList
      elem.elements.each do |e|
        emit_init_element(values, e, func_name)
      end
    when TypedAST::VarRef
      if g = @globals[{func_name, elem.name}]? || @globals[{"", elem.name}]?
        values << Source::Token::StringValue.new(g.global_name)
      elsif elem.type.is_a?(Type::Fn)
        name = @builder.@static_func_names_map[elem.name]? || elem.name
        values << Source::Token::StringValue.new(name)
      else
        raise error("Not found var ref #{elem.name}", elem)
      end
    when TypedAST::AddrOf
      emit_init_element(values, elem.operand, func_name)
    else
      raise error("Unsupported init element: #{elem.class}", elem)
    end
  end

  def generate_function(func : TypedAST::Function)
    @vars_stack = [Hash(String, VarInfo).new]
    @scope_counter = 0

    @params.clear
    @local_marks.clear

    @current_function_name = func.name
    @current_function = func

    attrs = Mod::FuncDef::Attr.new(0)
    attrs |= Mod::FuncDef::Attr::Vaarg if func.vaarg
    attrs |= Mod::FuncDef::Attr::Private if func.is_static
    node = Source::Node.new(Opcode::Code::FUNC)
    func_def = Mod::FuncDef.new(node, mod, func.name, func.type_fn, attrs)

    if body = func.body
      func_def.body = build_seq do
        func.params.each_value do |p|
          if p.changed
            m_name = mangled_name(p.name)
            current_vars[p.name] = VarInfo.new(p.type, m_name)
            emit_op Opcode::Param.new(p.index)
            emit_local(m_name, p.type)
            emit_op Opcode::Store.new
          else
            @params[p.name] = p.index
          end
        end

        body.each { |stmt| generate_stmt(stmt) }
      end
    end

    mod.func_defs[func.name] = func_def

    @current_function_name = ""
    @current_function = nil
  end

  def generate_stmt(stmt : TypedAST::ExprStmt)
    generate_expr(stmt.expr)
    emit_op(Opcode::Stack.new(:drop)) unless stmt.expr.type.eq?(typer.void)
  end

  def generate_stmt(stmt : TypedAST::Return)
    if v = stmt.value
      generate_expr(v)
    end
    emit_op(Opcode::Ret.new)
  end

  def generate_stmt(stmt : TypedAST::Block)
    push_scope
    stmt.body.each { |s| generate_stmt(s) }
    pop_scope
  end

  def generate_stmt(stmt : TypedAST::VarDecl)
    if vs = stmt.vla_sizes
      m_name = mangled_name(stmt.name)
      current_vars[stmt.name] = VarInfo.new(stmt.var_type, m_name, var_decl: stmt)
      generate_vla_alloca(vs.dup, stmt.var_type, m_name)
    elsif stmt.is_static
    elsif stmt.init.is_a?(TypedAST::ZeroInitializer)
      m_name = mangled_name(stmt.name)
      current_vars[stmt.name] = VarInfo.new(stmt.var_type, m_name)

      emit_op(Opcode::SizeOf.new(stmt.var_type))
      emit_op(push(0, typer.u8))
      emit_local(m_name, stmt.var_type)
      emit_op(Opcode::Addr.new)
      emit_op(Opcode::Call.new("memset", 0))
      emit_op(Opcode::Stack.new(:drop))
    else
      m_name = mangled_name(stmt.name)
      current_vars[stmt.name] = VarInfo.new(stmt.var_type, m_name)

      if init = stmt.init
        if stmt.var_type.is_a?(Type::FlatType) && init.is_a?(TypedAST::StringLiteral)
          str = init.value
          flat_type = stmt.var_type.as(Type::FlatType)
          count = flat_type.elements_count.to_i

          (count - str.size).times do
            emit_op(push(0, typer.u8))
          end

          str.bytes.reverse_each do |ch|
            emit_op(push(ch, typer.u8))
          end

          emit_op(Opcode::Create.new(stmt.var_type))
          emit_local(m_name, stmt.var_type)
          emit_op(Opcode::Store.new)
        else
          generate_expr(init)
          emit_local(m_name, stmt.var_type)
          emit_op(Opcode::Store.new)
        end
      end
    end
  end

  private def generate_vla_alloca(nodes : Array(TypedAST::Node), type : Type, name : String?)
    first = nodes.shift?
    return unless first

    generate_expr(first)
    first_slot = tmp_name("first_slot")
    emit_op(Opcode::Slot.new(first_slot))
    emit_op(Opcode::Slot.new(first_slot))

    target_type = type.as(Type::PtrType).target_type
    emit_op(Opcode::Alloca.new(target_type))

    alloca_slot = tmp_name("alloca_slot")
    emit_op(Opcode::Slot.new(alloca_slot))

    if name
      emit_op(Opcode::Slot.new(alloca_slot))
      emit_local(name, type)
      emit_op(Opcode::Store.new)
    else
      emit_op(Opcode::Slot.new(alloca_slot))
    end

    return unless nodes.first?

    index_var = tmp_name("vla_index")
    emit_op(push(0))
    emit_local(index_var, typer.i32)
    emit_op(Opcode::Store.new)

    body_seq = build_seq do
      generate_vla_alloca(nodes, target_type, nil)
      emit_local(index_var, typer.i32)
      emit_op(Opcode::Slot.new(alloca_slot))
      emit_op(Opcode::Binary.new(:add))
      emit_op(Opcode::Deref.new)
      emit_op(Opcode::Store.new)
    end

    cond_seq = build_seq do
      emit_op(Opcode::Slot.new(first_slot))
      emit_local(index_var, typer.i32)
      emit_op(Opcode::Binary.new(:less))
    end

    step_seq = build_seq do
      emit_op(push(1))
      emit_local(index_var, typer.i32)
      emit_op(Opcode::Binary.new(:add))
      emit_local(index_var, typer.i32)
      emit_op(Opcode::Store.new)
    end

    emit_op(Opcode::Loop.new(Opcode::Seq.new, cond_seq, body_seq, step_seq))
  end

  def generate_stmt(stmt : TypedAST::If)
    generate_expr(stmt.condition)

    push_scope
    then_seq = build_seq { stmt.then_body.each { |s| generate_stmt(s) } }
    pop_scope

    unless stmt.else_body.empty?
      push_scope
      else_seq = build_seq { stmt.else_body.each { |s| generate_stmt(s) } }
      pop_scope
    else
      else_seq = Opcode::Seq.new
    end

    emit_op Opcode::If.new(then_seq, else_seq)
  end

  def generate_stmt(stmt : TypedAST::While)
    init_seq = Opcode::Seq.new
    step_seq = Opcode::Seq.new

    cond_seq = build_seq { generate_expr(stmt.condition) }
    push_scope
    body_seq = build_seq { stmt.body.each { |s| generate_stmt(s) } }
    pop_scope

    emit_op Opcode::Loop.new(init_seq, cond_seq, body_seq, step_seq)
  end

  def generate_stmt(stmt : TypedAST::For)
    stmt.init.each { |s| generate_stmt(s) }

    init_seq = Opcode::Seq.new

    cond_seq = build_seq do
      if cond = stmt.condition
        generate_expr(cond)
      else
        emit_op push(true)
      end
    end

    push_scope
    body_seq = build_seq { stmt.body.each { |s| generate_stmt(s) } }
    pop_scope

    step_seq = build_seq { stmt.update.each { |s| generate_stmt(s) } }
    emit_op Opcode::Loop.new(init_seq, cond_seq, body_seq, step_seq)
  end

  def generate_stmt(stmt : TypedAST::DoWhile)
    init_seq = Opcode::Seq.new
    step_seq = Opcode::Seq.new

    cond_seq = Opcode::Seq.new.tap { |seq| seq << push(true) }

    push_scope
    body_seq = build_seq do
      stmt.body.each { |s| generate_stmt(s) }

      generate_expr(stmt.condition)
      emit_op Opcode::Unary.new(:lnot)
      emit_op Opcode::If.new(Opcode::Seq.new.tap { |seq| seq << Opcode::Break.new }, Opcode::Seq.new)
    end
    pop_scope

    emit_op Opcode::Loop.new(init_seq, cond_seq, body_seq, step_seq)
  end

  def generate_stmt(stmt : TypedAST::Break)
    emit_op Opcode::Break.new
  end

  def generate_stmt(stmt : TypedAST::Continue)
    emit_op Opcode::Next.new
  end

  def generate_stmt(stmt : TypedAST::Assign)
    generate_expr(stmt.right)
    generate_expr(stmt.left)
    emit_op Opcode::Store.new
  end

  def generate_stmt(stmt : TypedAST::Goto)
    emit_op Opcode::Goto.new([stmt.label])
  end

  def generate_stmt(stmt : TypedAST::Label)
    emit_op Opcode::Label.new(stmt.label)
  end

  def generate_stmt(stmt : TypedAST::Switch)
    label = stmt.label_prefix
    @switch_count += 1

    generate_expr(stmt.value)
    switch_val = "#{label}_val"
    emit_local(switch_val, stmt.value.type)
    emit_op Opcode::Store.new

    stmt.cases.each do |c|
      if val = c.value
        emit_op push(val, stmt.value.type)
        emit_local(switch_val, stmt.value.type)
        emit_op Opcode::Binary.new(:eq)
        emit_op Opcode::If.new(Opcode::Seq.new.tap { |seq| seq << Opcode::Goto.new([c.label]) }, Opcode::Seq.new)
      else
        emit_op Opcode::Goto.new([c.label])
      end
    end

    emit_op Opcode::Goto.new(["#{label}_end"])
    stmt.body.each { |s| generate_stmt(s) }
    emit_op Opcode::Label.new("#{label}_end")
  end

  def generate_expr(expr : TypedAST::IntLiteral)
    if expr.type.eq?(typer.i32)
      emit_op push(expr.value)
    else
      emit_op push(expr.value, expr.type)
    end
  end

  def generate_expr(expr : TypedAST::FloatLiteral)
    if expr.type.eq?(typer.f64)
      emit_op(push(expr.value))
    else
      emit_op(push(expr.value, expr.type))
    end
  end

  def generate_expr(expr : TypedAST::CharLiteral)
    if expr.type.eq?(typer.i32)
      emit_op push(expr.value)
    else
      emit_op push(expr.value, expr.type)
    end
  end

  def generate_expr(expr : TypedAST::StringLiteral)
    emit_op push(expr.value)
  end

  def generate_expr(expr : TypedAST::VarRef)
    name = expr.name
    if var = find_var(name)
      emit_local(var.mangled_name, expr.type)
    elsif param = @params[name]?
      emit_op(Opcode::Param.new(param))
    elsif g = @globals[{@current_function_name, expr.name}]? || @globals[{"", expr.name}]?
      emit_op(Opcode::Global.new(g.global_name))
    elsif expr.type.is_a?(Type::Fn)
      if name2 = @builder.@static_func_names_map[name]?
        name = name2
      end
      emit_op(Opcode::Addr.new(name))
    else
      raise error("Not found var ref #{name}", expr)
    end
  end

  def generate_expr(expr : TypedAST::BinaryOp)
    case expr.op
    when :store
    when :land
      tmp = tmp_name("__sc_and")
      generate_expr(expr.left)
      emit_local(tmp, typer.bool)
      emit_op Opcode::Store.new
      emit_local(tmp, typer.bool)
      emit_op Opcode::If.new(build_seq do
        generate_expr(expr.right)
        emit_local(tmp, typer.bool)
        emit_op Opcode::Store.new
      end, Opcode::Seq.new)
      emit_local(tmp, typer.bool)
    when :lor
      tmp = tmp_name("__sc_or")
      generate_expr(expr.left)
      emit_local(tmp, typer.bool)
      emit_op Opcode::Store.new
      emit_local(tmp, typer.bool)
      emit_op Opcode::If.new(Opcode::Seq.new, build_seq do
        generate_expr(expr.right)
        emit_local(tmp, typer.bool)
        emit_op Opcode::Store.new
      end)
      emit_local(tmp, typer.bool)
    when :comma
      generate_expr(expr.left)
      emit_op Opcode::Stack.new(:drop) unless expr.left.type.eq?(typer.void)
      generate_expr(expr.right)
    else
      generate_expr(expr.right)
      generate_expr(expr.left)
      emit_op Opcode::Binary.new(OP_TO_OPCODE[expr.op])
    end
  end

  OP_TO_OPCODE = {
    add:      Myc::Opcode::Binary::Op::Add,
    sub:      Myc::Opcode::Binary::Op::Sub,
    mul:      Myc::Opcode::Binary::Op::Mul,
    div:      Myc::Opcode::Binary::Op::Div,
    rem:      Myc::Opcode::Binary::Op::Rem,
    and:      Myc::Opcode::Binary::Op::And,
    or:       Myc::Opcode::Binary::Op::Or,
    xor:      Myc::Opcode::Binary::Op::Xor,
    shl:      Myc::Opcode::Binary::Op::Shl,
    shr:      Myc::Opcode::Binary::Op::Shr,
    sar:      Myc::Opcode::Binary::Op::Sar,
    rotl:     Myc::Opcode::Binary::Op::Rotl,
    rotr:     Myc::Opcode::Binary::Op::Rotr,
    eq:       Myc::Opcode::Binary::Op::Eq,
    not_eq:   Myc::Opcode::Binary::Op::NotEq,
    less:     Myc::Opcode::Binary::Op::Less,
    less_eq:  Myc::Opcode::Binary::Op::LessEq,
    more:     Myc::Opcode::Binary::Op::More,
    more_eq:  Myc::Opcode::Binary::Op::MoreEq,
    min:      Myc::Opcode::Binary::Op::Min,
    max:      Myc::Opcode::Binary::Op::Max,
    copysign: Myc::Opcode::Binary::Op::Copysign,
  }

  def generate_expr(expr : TypedAST::UnaryOp)
    case expr.op
    when :neg
      generate_expr(expr.operand)
      emit_op(Opcode::Unary.new(:neg))
    when :lnot
      generate_expr(expr.operand)
      emit_op(Opcode::Unary.new(:lnot))
    when :bnot
      generate_expr(expr.operand)
      emit_op(Opcode::Unary.new(:bnot))
    when :postfix_inc, :postfix_dec
      inc_type = expr.operand.type.is_a?(Type::PtrType) ? typer.u64 : expr.operand.type

      if expr.is_statement
        emit_op push(1, inc_type)
        generate_expr(expr.operand)
        emit_op Opcode::Binary.new(expr.op == :postfix_inc ? Opcode::Binary::Op::Add : Opcode::Binary::Op::Sub)
        generate_expr(expr.operand)
        emit_op Opcode::Store.new
      else
        tmp_name = tmp_name("__tmp")
        current_vars[tmp_name] = VarInfo.new(expr.type, tmp_name)

        generate_expr(expr.operand)
        emit_local(tmp_name, expr.type)
        emit_op Opcode::Store.new

        emit_op push(1, inc_type)
        generate_expr(expr.operand)
        emit_op Opcode::Binary.new(expr.op == :postfix_inc ? Opcode::Binary::Op::Add : Opcode::Binary::Op::Sub)
        generate_expr(expr.operand)
        emit_op Opcode::Store.new

        emit_local(tmp_name, expr.type)
        current_vars.delete(tmp_name)
      end
    when :prefix_inc, :prefix_dec
      inc_type = expr.operand.type.is_a?(Type::PtrType) ? typer.u64 : expr.operand.type
      emit_op push(1, inc_type)
      generate_expr(expr.operand)
      emit_op Opcode::Binary.new(expr.op == :prefix_inc ? Opcode::Binary::Op::Add : Opcode::Binary::Op::Sub)
      generate_expr(expr.operand)
      emit_op Opcode::Store.new
      generate_expr(expr.operand) unless expr.is_statement
    when :vaarg
      generate_expr(expr.operand)
      emit_op(Opcode::Va.new(:arg, expr.type))
    else
      raise error("unknown unary #{expr.op}", expr)
    end
  end

  def generate_expr(expr : TypedAST::AssignExpr)
    generate_expr(expr.left)
    generate_expr(expr.right)
    emit_op(Opcode::Stack.new(:swap2))
    emit_op(Opcode::Store.new)
    generate_expr(expr.left)
  end

  def generate_expr(expr : TypedAST::Call)
    if expr.is_invoke
      callee = expr.args.first
      invoke_args = expr.args[1..]
      invoke_args.reverse.each { |arg| generate_expr(arg) }
      generate_expr(callee)
      emit_op(Opcode::Invoke.new(expr.vaargs_count))
    else
      fname = expr.func_name
      if fname.starts_with?("__builtin")
        if generate_builtin(fname, expr.type, expr.args)
          return
        end
      end
      if fname2 = @builder.@static_func_names_map[fname]?
        fname = fname2
      end
      expr.args.reverse.each { |arg| generate_expr(arg) }
      emit_op(Opcode::Call.new(fname, expr.vaargs_count))
    end
  end

  def generate_expr(expr : TypedAST::Cast)
    generate_expr(expr.operand)
    if expr.type.eq?(typer.void)
      emit_op(Opcode::Stack.new(:drop))
    else
      emit_op(Opcode::As.new(expr.type))
    end
  end

  def generate_expr(expr : TypedAST::Subscript)
    generate_expr(expr.index)
    generate_expr(expr.array)

    case type = expr.array.type
    when Type::FlatType
      emit_op(Opcode::Addr.new)
      elem_type = type.target_type
      emit_op Opcode::As.new(typer.to_ptr(elem_type, Location.new("", 0)))
    end

    emit_op(Opcode::Binary.new(:add))
    emit_op(Opcode::Deref.new)
  end

  def generate_expr(expr : TypedAST::FieldAccess)
    generate_expr(expr.obj)
    emit_op(Opcode::Field.new(expr.field_index))
  end

  def generate_expr(expr : TypedAST::AddrOf)
    generate_expr(expr.operand)
    emit_op(Opcode::Addr.new)
  end

  def generate_expr(expr : TypedAST::Deref)
    generate_expr(expr.operand)
    emit_op(Opcode::Deref.new)
  end

  def generate_expr(expr : TypedAST::SizeOf)
    emit_op(Opcode::SizeOf.new(expr.target_type))
  end

  def generate_expr(expr : TypedAST::SizeOfVla)
    elem_type = get_vla_leaf_type(expr.var_ref.type)
    emit_op(Opcode::SizeOf.new(elem_type))
    if (var = find_var(expr.var_ref.name)) && (var_decl = var.var_decl) && (vla_sizes = var_decl.vla_sizes)
      vla_sizes.each do |sz|
        generate_expr(sz)
        emit_op(Opcode::As.new(typer.u64))
        emit_op(Opcode::Binary.new(:mul))
      end
    else
      raise error("not find_var", expr)
    end
  end

  private def get_vla_leaf_type(type : Type) : Type
    current = type

    while current.is_a?(Type::PtrType)
      current = current.target_type
    end
    current
  end

  def generate_expr(expr : TypedAST::InitList)
    case expr_type = expr.type
    when Type::EnumType
      if expr.elements.empty?
        emit_op(push(0))
        emit_op(Opcode::Create.new(expr_type))
      else
        payload = expr.elements[0]
        variant_type = expr_type.data.values.find do |v|
          v.value_types.first?.try(&.eq?(payload.type))
        end

        expr.elements.reverse.each { |e| generate_expr(e) }

        if variant_type
          emit_op(Opcode::Create.new(variant_type))
          emit_op(Opcode::As.new(expr_type))
        else
          emit_op(Opcode::Create.new(expr_type))
        end
      end
    else
      expr.elements.reverse.each { |e| generate_expr(e) }
      emit_op(Opcode::Create.new(expr.type))
    end
  end

  def generate_expr(expr : TypedAST::Conditional)
    if expr.type.eq?(typer.void)
      generate_expr(expr.condition)
      emit_op Opcode::If.new(build_seq { generate_expr(expr.then_expr) }, build_seq { generate_expr(expr.else_expr) })
    else
      tmp = tmp_name("__ternary")

      generate_expr(expr.condition)
      then_seq = build_seq do
        generate_expr(expr.then_expr)
        emit_local(tmp, expr.type)
        emit_op Opcode::Store.new
      end

      else_seq = build_seq do
        generate_expr(expr.else_expr)
        emit_local(tmp, expr.type)
        emit_op Opcode::Store.new
      end

      emit_op Opcode::If.new(then_seq, else_seq)
      emit_local(tmp, expr.type)
    end
  end

  def generate_expr(expr : TypedAST::ZeroInitializer)
  end

  def generate_expr(expr : TypedAST::AddrLabel)
    emit_op(Opcode::Addr.new(expr.label))
  end

  def generate_stmt(stmt : TypedAST::IndirectGoto)
    generate_expr(stmt.target)
    if (f = @current_function) && (l = f.addr_labels)
      if l.size == 1
        emit_op Opcode::Stack.new(:drop)
      elsif l.size == 0
        raise error("indirect labels not found", stmt)
      end
      emit_op Opcode::Goto.new(l)
    else
      raise error("indirect labels not found", stmt)
    end
  end

  def generate_expr(expr : TypedAST::StmtExpr)
    push_scope
    expr.body.each { |s| generate_stmt(s) }

    if result = expr.result
      generate_expr(result)
    end
    pop_scope
  end

  private def returns_void?(call : TypedAST::Call) : Bool
    call.type.eq?(typer.void)
  end

  def tmp_name(prefix = "")
    s = "#{prefix}_#{@temp_counter}"
    @temp_counter += 1
    s
  end

  private def emit_local(mangled_name : String, type : Type)
    if @local_marks.includes?(mangled_name)
      emit_op(Opcode::Local.new(mangled_name))
    else
      emit_op(Opcode::Local.new(mangled_name, type))
      @local_marks << mangled_name
    end
  end

  private def error(msg : String, node : TypedAST::Node | TypedAST::Stmt)
    Error::ErrorLoc.new(msg, node.location)
  end

  private def emit_op(op : Opcode)
    @seq << op
  end

  private def build_seq(&) : Opcode::Seq
    s = Opcode::Seq.new
    was_seq = @seq
    @seq = s
    yield
    @seq = was_seq
    s
  end

  private def push(v : Int, type = nil)
    Opcode::Push.new(Source::Token::IntValue.new(v.to_i64), type)
  end

  private def push(v : Float, type = nil)
    Opcode::Push.new(Source::Token::FloatValue.new(v), type)
  end

  private def push(v : String, type = nil)
    Opcode::Push.new(Source::Token::StringValue.new(v), type)
  end

  private def push(v : Bool, type = nil)
    Opcode::Push.new(Source::Token::BoolValue.new(v), type)
  end

  private def push(v, type = nil)
    raise error("unexpected value #{v.inspect}")
  end
end
