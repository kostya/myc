class Myc::Mycc::CodeGenerator
  getter io : IO
  getter typer : Typer
  getter builder : ASTBuilder

  class VarInfo
    getter type : Type
    getter is_static : Bool
    getter unique_name : String?
    getter mangled_name : String

    def initialize(@type, @mangled_name, @is_static = false, @unique_name = nil)
    end
  end

  def initialize(@typer, @builder)
    @indent = 0
    @io = IO::Memory.new
    @additional_io = IO::Memory.new
    @vars_stack = [Hash(String, VarInfo).new]
    @params = Hash(String, Int32).new
    @globals = Hash(String, TypedAST::VarDecl).new
    @local_marks = Set(String).new
    @switch_count = 0
    @scope_counter = 0
    @temp_counter = 0_u64
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

  def generate(program : TypedAST::Program) : Tuple(IO, IO)
    program.structs.each do |name, fields|
      emit("STRUCT :#{name}")
      @indent += 1
      fields.each do |_, field_type|
        emit("TYPE #{type_s(field_type)}")
      end
      struct_type = typer.map[name].as(Type::StructType)
      if ea = struct_type.explicit_alignment
        emit("ALIGN #{ea}")
      end
      @indent -= 1
      emit("ENDSTRUCT")
    end

    program.unions.each do |name, fields|
      emit("ENUM :#{name}")
      @indent += 1
      emit("TAG SKIP")
      fields.each do |field_name, field_type|
        emit("VARIANT :#{field_name}")
        @indent += 1
        emit("TYPE #{type_s(field_type)}")
        @indent -= 1
      end
      enum_type = typer.map[name].as(Type::EnumType)
      if ea = enum_type.explicit_alignment
        emit("ALIGN #{ea}")
      end
      @indent -= 1
      emit("ENDENUM")
    end

    program.globals.each do |var|
      emit("GLOBAL :#{var.name}")
      @indent += 1
      emit("TYPE #{type_s(var.var_type)}")
      @indent -= 1

      if init = var.init
        emit("INITIAL")
        emit_init_element(init)
      end

      emit("PRIVATE") if var.is_static

      emit("ENDGLOBAL")

      @globals[var.original_name] = var
    end

    program.functions.each do |_, f|
      generate_function(f)
    end
    io.rewind
    @additional_io.rewind
    {io, @additional_io}
  end

  private def emit_init_element(elem)
    case elem
    when TypedAST::IntLiteral
      emit(" #{elem.value}")
    when TypedAST::CharLiteral
      emit(" #{elem.value}")
    when TypedAST::FloatLiteral
      emit(" #{elem.value}")
    when TypedAST::StringLiteral
      if elem.type.is_a?(Type::PtrType)
        emit(" \"#{Backend::AbstractBuilder.escaped_string(elem.value)}\"")
      else
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
        emit(" #{str}")
      end
    when TypedAST::Cast
      emit_init_element(elem.operand)
    when TypedAST::ZeroInitializer
      emit(" 0" * elem.type.flat_elements_count)
    when TypedAST::InitList
      elem.elements.each do |elem|
        emit_init_element(elem)
      end
    when TypedAST::VarRef
      if mapped_name = @builder.@static_func_names_map[elem.name]?
        emit(" #{mapped_name}")
      else
        emit(" #{elem.name}")
      end
    when TypedAST::AddrOf
      emit_init_element(elem.operand)
    else
      raise error("Unsupported init element: #{elem.class}", elem)
    end
  end

  private def emit(str : String)
    @io << "  " * @indent << str << '\n'
  end

  def generate_function(func : TypedAST::Function)
    @vars_stack = [Hash(String, VarInfo).new]
    @scope_counter = 0

    @params.clear
    @local_marks.clear

    emit("FUNC :#{func.name}")
    @indent += 1

    unless func.params.empty?
      emit("ARGS")
      @indent += 1
      sorted_params = func.params.values.sort_by(&.index)
      sorted_params.each { |p| emit("  TYPE #{type_s(p.type)}") }
      @indent -= 1
    end

    if func.return_type.id_name != "void"
      emit("RETURN")
      @indent += 1
      emit("  TYPE #{type_s(func.return_type)}")
      @indent -= 1
    end

    if func.vaarg || func.is_static
      emit("ATTRIBUTES")
      if func.vaarg
        emit("ATTR :vaarg")
      elsif func.is_static
        emit("ATTR :private")
      end
    end

    if body = func.body
      emit("BODY")
      @indent += 1

      func.params.each_value do |p|
        if p.changed
          m_name = mangled_name(p.name)
          current_vars[p.name] = VarInfo.new(p.type, m_name)
          emit("PARAM #{p.index}")
          emit_local(m_name, p.type)
          emit("STORE")
        else
          @params[p.name] = p.index
        end
      end

      body.each { |stmt| generate_stmt(stmt) }
      @indent -= 1
    end

    emit("ENDFUNC")
    @indent -= 1
  end

  def generate_stmt(stmt : TypedAST::ExprStmt)
    generate_expr(stmt.expr)

    unless stmt.expr.type.id_name == "void"
      emit("STACK :drop")
    end
  end

  def generate_stmt(stmt : TypedAST::Return)
    if v = stmt.value
      generate_expr(v)
    end
    emit("RET")
  end

  def generate_stmt(stmt : TypedAST::Block)
    push_scope
    stmt.body.each { |s| generate_stmt(s) }
    pop_scope
  end

  def generate_stmt(stmt : TypedAST::VarDecl)
    if stmt.is_vla
      generate_expr(stmt.init.not_nil!)
      emit("ALLOCA #{type_s(stmt.var_type.as(Type::PtrType).target_type)}")
      m_name = mangled_name(stmt.name)
      current_vars[stmt.name] = VarInfo.new(stmt.var_type, m_name)
      emit_local(m_name, stmt.var_type)
      emit("STORE")
    elsif stmt.is_static
    elsif stmt.init.is_a?(TypedAST::ZeroInitializer)
      m_name = mangled_name(stmt.name)
      current_vars[stmt.name] = VarInfo.new(stmt.var_type, m_name)

      emit("SIZEOF #{type_s(stmt.var_type)}")
      emit("PUSH 0 :u8")
      emit_local(m_name, stmt.var_type)
      emit("ADDR")
      emit("CALL :memset")
      emit("STACK :drop")
    else
      m_name = mangled_name(stmt.name)
      current_vars[stmt.name] = VarInfo.new(stmt.var_type, m_name)
      if init = stmt.init
        if stmt.var_type.is_a?(Type::FlatType) && init.is_a?(TypedAST::StringLiteral)
          str = init.value
          flat_type = stmt.var_type.as(Type::FlatType)
          count = flat_type.elements_count.to_i

          (count - str.size).times do
            emit("PUSH 0 :u8")
          end

          str.bytes.reverse_each do |ch|
            emit("PUSH #{ch} :u8")
          end

          emit("CREATE #{type_s(stmt.var_type)}")
          emit_local(m_name, stmt.var_type)
          emit("STORE")
        else
          generate_expr(init)
          emit_local(m_name, stmt.var_type)
          emit("STORE")
        end
      end
    end
  end

  def generate_stmt(stmt : TypedAST::If)
    generate_expr(stmt.condition)
    emit("IF")
    @indent += 1

    emit("THEN")
    @indent += 1
    push_scope
    stmt.then_body.each { |s| generate_stmt(s) }
    pop_scope
    @indent -= 1

    unless stmt.else_body.empty?
      emit("ELSE")
      @indent += 1
      push_scope
      stmt.else_body.each { |s| generate_stmt(s) }
      pop_scope
      @indent -= 1
    end

    @indent -= 1
    emit("ENDIF")
  end

  def generate_stmt(stmt : TypedAST::While)
    emit("LOOP")
    @indent += 1

    emit("COND")
    @indent += 1
    generate_expr(stmt.condition)
    @indent -= 1

    emit("BODY")
    @indent += 1
    push_scope
    stmt.body.each { |s| generate_stmt(s) }
    pop_scope
    @indent -= 1

    emit("STEP")
    @indent -= 1
    emit("ENDLOOP")
  end

  def generate_stmt(stmt : TypedAST::For)
    stmt.init.each { |s| generate_stmt(s) }

    emit("LOOP")
    @indent += 1

    emit("COND")
    @indent += 1
    if cond = stmt.condition
      generate_expr(cond)
    else
      emit("PUSH true")
    end
    @indent -= 1

    emit("BODY")
    @indent += 1
    push_scope
    stmt.body.each { |s| generate_stmt(s) }
    pop_scope
    @indent -= 1

    emit("STEP")
    stmt.update.each { |s| generate_stmt(s) }

    @indent -= 1
    emit("ENDLOOP")
  end

  def generate_stmt(stmt : TypedAST::DoWhile)
    emit("LOOP")
    @indent += 1

    emit("COND")
    @indent += 1
    emit("PUSH true")
    @indent -= 1

    emit("BODY")
    @indent += 1
    push_scope
    stmt.body.each { |s| generate_stmt(s) }

    generate_expr(stmt.condition)
    emit("IF")
    @indent += 1
    emit("THEN")
    @indent += 1

    @indent -= 1
    emit("ELSE")
    @indent += 1
    emit("BREAK")
    @indent -= 1
    @indent -= 1
    emit("ENDIF")
    pop_scope
    @indent -= 1

    emit("STEP")
    @indent -= 1
    emit("ENDLOOP")
  end

  def generate_stmt(stmt : TypedAST::Break)
    emit("BREAK")
  end

  def generate_stmt(stmt : TypedAST::Continue)
    emit("NEXT")
  end

  def generate_stmt(stmt : TypedAST::Assign)
    generate_expr(stmt.right)
    generate_expr(stmt.left)
    emit("STORE")
  end

  def generate_stmt(stmt : TypedAST::Goto)
    emit("GOTO \"#{stmt.label}\"")
  end

  def generate_stmt(stmt : TypedAST::Label)
    emit("LABEL \"#{stmt.label}\"")
  end

  def generate_stmt(stmt : TypedAST::Switch)
    label = stmt.label_prefix
    @switch_count += 1

    generate_expr(stmt.value)
    switch_val = "#{label}_val"
    emit_local(switch_val, stmt.value.type)
    emit("STORE")

    stmt.cases.each do |c|
      if c.values.present?
        c.values.each do |val|
          val_type_s = type_s(stmt.value.type)
          emit("PUSH #{val} #{val_type_s}")
          emit_local(switch_val, stmt.value.type)
          emit("BINARY :eq")
          emit("IF")
          @indent += 1
          emit("THEN GOTO \"#{c.label}\"")
          @indent -= 1
          emit("ENDIF")
        end
      else
        emit("GOTO \"#{c.label}\"")
      end
    end

    emit("GOTO \"#{label}_end\"")

    stmt.cases.each do |c|
      emit("LABEL \"#{c.label}\"")
      push_scope
      c.body.each { |s| generate_stmt(s) }
      pop_scope
    end

    emit("LABEL \"#{label}_end\"")
  end

  def generate_expr(expr : TypedAST::IntLiteral)
    if expr.type.eq?(typer.i32)
      emit("PUSH #{expr.value}")
    else
      emit("PUSH #{expr.value} #{type_s(expr.type)}")
    end
  end

  def generate_expr(expr : TypedAST::FloatLiteral)
    val_str = case val = expr.value
              when Float64::INFINITY
                "+inf"
              when -Float64::INFINITY
                "-inf"
              when .nan?
                "+nan"
              else
                val.to_s
              end
    if expr.type.eq?(typer.f64)
      emit("PUSH #{val_str}")
    else
      emit("PUSH #{val_str} #{type_s(expr.type)}")
    end
  end

  def generate_expr(expr : TypedAST::CharLiteral)
    if expr.type.eq?(typer.i32)
      emit("PUSH #{expr.value}")
    else
      emit("PUSH #{expr.value} #{type_s(expr.type)}")
    end
  end

  def generate_expr(expr : TypedAST::StringLiteral)
    emit("PUSH #{expr.value.inspect}")
  end

  def generate_expr(expr : TypedAST::VarRef)
    name = expr.name
    if var = find_var(name)
      emit_local(var.mangled_name, expr.type)
    elsif param = @params[name]?
      emit("PARAM #{param}")
    elsif g = @globals[name]?
      emit("GLOBAL :#{g.name}")
    elsif expr.type.is_a?(Type::Fn)
      if name2 = @builder.@static_func_names_map[name]?
        name = name2
      end
      emit("ADDR :#{name}")
    end
  end

  def generate_expr(expr : TypedAST::BinaryOp)
    case expr.op
    when :store
    when :land
      tmp = tmp_name("__sc_and")

      generate_expr(expr.left)
      emit_local(tmp, typer.bool)
      emit("STORE")

      emit_local(tmp, typer.bool)
      emit("IF")
      @indent += 1
      emit("THEN")
      @indent += 1
      generate_expr(expr.right)
      emit_local(tmp, typer.bool)
      emit("STORE")
      @indent -= 1
      emit("ELSE")
      @indent += 1

      @indent -= 1
      @indent -= 1
      emit("ENDIF")

      emit_local(tmp, typer.bool)
    when :lor
      tmp = tmp_name("__sc_or")

      generate_expr(expr.left)
      emit_local(tmp, typer.bool)
      emit("STORE")

      emit_local(tmp, typer.bool)
      emit("IF")
      @indent += 1
      emit("THEN")
      @indent += 1

      @indent -= 1
      emit("ELSE")
      @indent += 1
      generate_expr(expr.right)
      emit_local(tmp, typer.bool)
      emit("STORE")
      @indent -= 1
      @indent -= 1
      emit("ENDIF")

      emit_local(tmp, typer.bool)
    when :comma
      generate_expr(expr.left)
      emit("STACK :drop") unless expr.left.type.eq?(typer.void)
      generate_expr(expr.right)
    else
      generate_expr(expr.right)
      generate_expr(expr.left)
      emit("BINARY :#{expr.op}")
    end
  end

  def generate_expr(expr : TypedAST::UnaryOp)
    case expr.op
    when :neg
      generate_expr(expr.operand)
      emit("UNARY :neg")
    when :lnot
      generate_expr(expr.operand)
      emit("UNARY :lnot")
    when :bnot
      generate_expr(expr.operand)
      emit("UNARY :bnot")
    when :postfix_inc, :postfix_dec
      inc_type = expr.operand.type.is_a?(Type::PtrType) ? typer.u64 : expr.operand.type

      if expr.is_statement
        emit("PUSH 1 #{type_s(inc_type)}")
        generate_expr(expr.operand)
        bin_op = expr.op == :postfix_inc ? "add" : "sub"
        emit("BINARY :#{bin_op}")
        generate_expr(expr.operand)
        emit("STORE")
      else
        tmp_name = tmp_name("__tmp")
        current_vars[tmp_name] = VarInfo.new(expr.type, tmp_name)

        generate_expr(expr.operand)
        emit_local(tmp_name, expr.type)
        emit("STORE")

        emit("PUSH 1 #{type_s(inc_type)}")
        generate_expr(expr.operand)
        bin_op = expr.op == :postfix_inc ? "add" : "sub"
        emit("BINARY :#{bin_op}")
        generate_expr(expr.operand)
        emit("STORE")

        emit_local(tmp_name, expr.type)
        current_vars.delete(tmp_name)
      end
    when :prefix_inc, :prefix_dec
      inc_type = expr.operand.type.is_a?(Type::PtrType) ? typer.u64 : expr.operand.type
      emit("PUSH 1 #{type_s(inc_type)}")
      generate_expr(expr.operand)
      bin_op = expr.op == :prefix_inc ? "add" : "sub"
      emit("BINARY :#{bin_op}")
      generate_expr(expr.operand)
      emit("STORE")
      generate_expr(expr.operand) unless expr.is_statement
    end
  end

  def generate_expr(expr : TypedAST::AssignExpr)
    generate_expr(expr.left)
    generate_expr(expr.right)
    emit("STACK :swap2")
    emit("STORE")
    generate_expr(expr.left)
  end

  def generate_expr(expr : TypedAST::Call)
    if expr.is_invoke
      callee = expr.args.first
      invoke_args = expr.args[1..]
      invoke_args.reverse.each { |arg| generate_expr(arg) }
      generate_expr(callee)
      emit("INVOKE#{expr.vaargs_count > 0 ? " #{expr.vaargs_count}" : ""}")
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
      emit("CALL :#{fname}#{expr.vaargs_count > 0 ? " #{expr.vaargs_count}" : ""}")
    end
  end

  def generate_expr(expr : TypedAST::Cast)
    generate_expr(expr.operand)
    if expr.type.eq?(typer.void)
      emit("STACK :drop")
    else
      emit("AS #{type_s(expr.type)}")
    end
  end

  def generate_expr(expr : TypedAST::Subscript)
    generate_expr(expr.index)
    generate_expr(expr.array)

    case type = expr.array.type
    when Type::FlatType
      emit("ADDR")
      elem_type = type.target_type
      emit("AS \"ptr<#{elem_type.id_name}>\"")
    end

    emit("BINARY :add")
    emit("DEREF")
  end

  def generate_expr(expr : TypedAST::FieldAccess)
    generate_expr(expr.obj)
    emit("FIELD #{expr.field_index}")
  end

  def generate_expr(expr : TypedAST::AddrOf)
    generate_expr(expr.operand)
    emit("ADDR")
  end

  def generate_expr(expr : TypedAST::Deref)
    generate_expr(expr.operand)
    emit("DEREF")
  end

  def generate_expr(expr : TypedAST::SizeOf)
    emit("SIZEOF #{type_s(expr.target_type)}")
  end

  def generate_expr(expr : TypedAST::InitList)
    expr.elements.reverse.each { |e| generate_expr(e) }
    emit("CREATE #{type_s(expr.type)}")
  end

  def generate_expr(expr : TypedAST::Conditional)
    if expr.type.eq?(typer.void)
      generate_expr(expr.condition)
      emit("IF")
      @indent += 1
      emit("THEN")
      @indent += 1
      generate_expr(expr.then_expr)
      @indent -= 1
      emit("ELSE")
      @indent += 1
      generate_expr(expr.else_expr)
      @indent -= 1
      @indent -= 1
      emit("ENDIF")
    else
      tmp = tmp_name("__ternary")

      generate_expr(expr.condition)
      emit("IF")
      @indent += 1
      emit("THEN")
      @indent += 1
      generate_expr(expr.then_expr)
      emit_local(tmp, expr.type)
      emit("STORE")
      @indent -= 1
      emit("ELSE")
      @indent += 1
      generate_expr(expr.else_expr)
      emit_local(tmp, expr.type)
      emit("STORE")
      @indent -= 1
      @indent -= 1
      emit("ENDIF")

      emit_local(tmp, expr.type)
    end
  end

  def generate_expr(expr : TypedAST::ZeroInitializer)
  end

  private def returns_void?(call : TypedAST::Call) : Bool
    call.type.id_name == "void"
  end

  private def type_s(type : Type) : String
    if type.needs_blit? || type.is_a?(Type::PtrType) || type.is_a?(Type::Fn)
      "\"#{type.id_name}\""
    else
      ":#{type.id_name}"
    end
  end

  def tmp_name(prefix = "")
    s = "#{prefix}_#{@temp_counter}"
    @temp_counter += 1
    s
  end

  private def emit_local(mangled_name : String, type : Type)
    if @local_marks.includes?(mangled_name)
      emit("LOCAL :#{mangled_name}")
    else
      emit("LOCAL :#{mangled_name} #{type_s(type)}")
      @local_marks << mangled_name
    end
  end

  private def error(msg : String, node : TypedAST::Node | TypedAST::Stmt)
    Error::ErrorLoc.new(msg, node.location)
  end
end
