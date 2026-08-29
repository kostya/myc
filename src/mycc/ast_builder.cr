class Myc::Mycc::ASTBuilder
  getter source : Source
  getter tu : Clang::TranslationUnit
  getter mod : Mod
  getter typer : Typer
  getter shared_types : Backend::Mycc::SharedTypes

  @current_return_type : Type?

  def initialize(@source, @tu, @typer, @shared_types)
    @mod = Myc::Mod.new("main", source.filename, @typer)
    @structs = Hash(String, Array({String, Type})).new
    @unions = {} of String => Array({String, Type})
    @current_function_name = ""
    @current_function_params = Hash(String, TypedAST::Function::ParamInfo).new
    @globals = [] of TypedAST::VarDecl
    @enum_values = {} of String => Int64
    @enum_types = {} of String => Type
    @called_functions = Set(String).new
    @switch_counter = 0_u64
    @unnamed_types_map = Hash(String, String).new
    @static_func_names_map = Hash(String, String).new
    @break_stack = Deque(TypedAST::Stmt).new
  end

  def build : TypedAST::Program
    functions = Hash(String, TypedAST::Function).new

    tu.cursor.visit_children do |cursor|
      if cursor.kind.struct_decl?
        name = cursor.spelling
        unless name.empty?
          unless mod.type_defs[name]? || typer.map[name]?
            struct_type = Type::StructType.new(location(cursor), name)
            node = cursor_to_node(cursor)
            mod.type_defs[name] = Mod::TypeDef.new(@mod, node, struct_type)
            typer.map[name] = struct_type
          end
        end
      elsif cursor.kind.union_decl?
        name = cursor.spelling
        unless name.empty?
          unless mod.type_defs[name]? || typer.map[name]?
            enum_type = Type::EnumType.new(location(cursor), name, nil)
            node = cursor_to_node(cursor)
            mod.type_defs[name] = Mod::TypeDef.new(@mod, node, enum_type)
            typer.map[name] = enum_type
          end
        end
      end
      Clang::ChildVisitResult::Continue
    end

    tu.cursor.visit_children do |cursor|
      if cursor.kind.var_decl?
        var_decl = build_var_decl(cursor)
        unless @globals.any? { |g| g.name == var_decl.name }
          @globals << var_decl
        end
      elsif cursor.kind.struct_decl?
        build_struct_decl(cursor)
      elsif cursor.kind.union_decl?
        build_union(cursor)
      elsif cursor.kind.enum_decl?
        build_enum(cursor)
      end
      Clang::ChildVisitResult::Continue
    end

    tu.cursor.visit_children do |cursor|
      if cursor.kind.function_decl?
        if source_kind(cursor).user_source?
          func = build_function(cursor)
          if func2 = functions[func.name]?
            if func.body
              functions[func.name] = func
            end
          else
            functions[func.name] = func
          end
        end
      end
      Clang::ChildVisitResult::Continue
    end

    called_functions_count = 0

    loop do
      break if called_functions_count == @called_functions.size
      fn_add_list = Set(String).new(@called_functions - functions.keys)
      called_functions_count = @called_functions.size

      tu.cursor.visit_children do |cursor|
        if cursor.kind.function_decl?
          if fn_add_list.includes?(cursor.spelling)
            func = build_function(cursor)
            functions[func.name] = func
          end
        end
        Clang::ChildVisitResult::Continue
      end
    end

    TypedAST::Program.new(functions, @structs, @unions, @globals)
  end

  private def auto_cast(node : TypedAST::Node, target_type : Type, loc : Location) : TypedAST::Node
    node = auto_decay(node)
    return node if node.type.eq?(target_type)
    from = node.type

    if (from.is_a?(Type::IntType) || from.is_a?(Type::FloatType) || from.is_a?(Type::PtrType)) &&
       target_type.is_a?(Type::BoolType)
      zero = from.is_a?(Type::FloatType) ? TypedAST::FloatLiteral.new(0.0, from, loc) : TypedAST::IntLiteral.new(0_i64, from, loc)
      return TypedAST::BinaryOp.new(:not_eq, node, zero, typer.bool, loc)
    end

    if (from.is_a?(Type::IntType) || from.is_a?(Type::FloatType) || from.is_a?(Type::BoolType)) &&
       (target_type.is_a?(Type::IntType) || target_type.is_a?(Type::FloatType) || target_type.is_a?(Type::BoolType))
      return TypedAST::Cast.new(node, target_type, loc)
    end

    if from.is_a?(Type::FlatType) && target_type.is_a?(Type::PtrType) &&
       from.target_type.eq?(target_type.as(Type::PtrType).target_type)
      addr = TypedAST::AddrOf.new(node, target_type, loc)
      return TypedAST::Cast.new(addr, target_type, loc)
    end

    if target_type.is_a?(Type::PtrType) && from.eq?(typer.voidp)
      return TypedAST::Cast.new(node, target_type, loc)
    end

    if from.is_a?(Type::PtrType) && target_type.eq?(typer.voidp)
      return TypedAST::Cast.new(node, target_type, loc)
    end

    if from.is_a?(Type::IntType) && (target_type.is_a?(Type::PtrType) || target_type.is_a?(Type::Fn)) &&
       node.is_a?(TypedAST::IntLiteral) && node.value == 0
      return TypedAST::Cast.new(node, target_type, loc)
    end

    if from.is_a?(Type::Fn) && target_type.eq?(typer.voidp)
      return TypedAST::Cast.new(node, target_type, loc)
    end

    if from.eq?(typer.voidp) && target_type.is_a?(Type::Fn)
      return TypedAST::Cast.new(node, target_type, loc)
    end

    node
  end

  private def build_function(cursor : Clang::Cursor) : TypedAST::Function
    name = cursor.spelling
    old_name = @current_function_name
    @current_function_name = name
    @current_function_params.clear
    body = nil

    func_type = get_type(cursor, cursor.type)
    return_type = get_type(cursor, cursor.result_type)
    @current_return_type = return_type

    param_names = [] of String
    children(cursor).each do |child|
      if child.kind.parm_decl?
        param_name = child.spelling
        param_name = "__param_#{param_names.size}" if param_name.empty?
        param_names << param_name
      end
    end

    if fn_type = func_type.as?(Type::Fn)
      fn_type.args.each_with_index do |arg_type, i|
        param_name = param_names[i]? || "__param_#{i}"
        if arg_type.is_a?(Type::FlatType)
          arg_type = typer.to_ptr(arg_type.target_type, location(cursor))
        end
        @current_function_params[param_name] = TypedAST::Function::ParamInfo.new(
          param_name, arg_type, @current_function_params.size
        )
      end
    end

    children(cursor).each do |child|
      case child.kind
      when .compound_stmt?
        body = [] of TypedAST::Stmt
        children(child).each { |c| build_stmt(c, body) }
      when .parm_decl?, .first_attr?, .type_ref?, .first_expr?,
           .warn_unused_result_attr?, .const_attr?, .visibility_attr?,
           .pure_attr?, .asm_label_attr?
      else
        raise error("Unhandled child: #{child.kind}", child)
      end
    end

    vaarg = func_type.is_a?(Type::Fn) ? func_type.vaarg : false
    is_static = cursor.storage_class.static?
    if is_static
      name2 = "static_fn_#{source.name}_#{name}"
      @static_func_names_map[name] = name2
      name = name2
    end

    TypedAST::Function.new(
      name,
      @current_function_params.dup,
      return_type,
      body,
      location(cursor),
      vaarg,
      is_static
    )
  ensure
    @current_return_type = nil
    @current_function_name = old_name.not_nil!
  end

  def build_body(cursor : Clang::Cursor, body : Array(TypedAST::Stmt))
    if cursor.kind.compound_stmt?
      children(cursor).each { |child| build_stmt(child, body) }
    else
      build_stmt(cursor, body)
    end
  end

  def build_body(cursor : Clang::Cursor) : Array(TypedAST::Stmt)
    Array(TypedAST::Stmt).new.tap { |body| build_body(cursor, body) }
  end

  private def build_struct_decl(cursor : Clang::Cursor) : Type
    name = cursor.spelling
    raise error("No struct name", cursor) if name.blank?

    if name.includes?("unnamed") || name.includes?("anonymous")
      if name2 = @unnamed_types_map[name]?
        name = name2
      else
        name2 = "__inline_type_#{source.name}_#{@unnamed_types_map.size}"
        @unnamed_types_map[name] = name2
        name = name2
      end
    end

    case struct_type = typer.map[name]? || mod.type_defs[name]?.try(&.type)
    when Type::StructType
    when Nil
      struct_type = Type::StructType.new(location(cursor), name)
      node = cursor_to_node(cursor)
      mod.type_defs[name] = Mod::TypeDef.new(@mod, node, struct_type)
      typer.map[name] = struct_type
    else
      raise error("Type #{name} already defined as #{struct_type.class}, but expected struct", cursor)
    end

    return struct_type unless struct_type.data.empty?

    fields = [] of {String, Type}
    children(cursor).each do |child|
      case child.kind
      when .field_decl?
        field_name = child.spelling
        field_type = get_type(child, child.type)
        fields << {field_name, field_type}
      when .union_decl?
        if child.spelling.includes?("anonymous")
          fields << {"__mycc_anon_field__#{fields.size}", build_union(child)}
        end
      when .packed_attr?
        struct_type.explicit_alignment = 1_u64
      when .aligned_attr?
        puts "warning ignore aligned attr for #{name}"
      when .struct_decl?
        if child.spelling.includes?("anonymous")
          fields << {"__mycc_anon_field__#{fields.size}", build_struct_decl(child)}
        end
      else
        raise error("Unhandled child: #{child.kind}", child)
      end
    end
    @structs[name] = fields
    if (f = @shared_types.struct_fields[name]?) && !f.empty?
    else
      @shared_types.struct_fields[name] = fields
    end
    struct_type.data = fields.map { |_, t| t }
    struct_type
  end

  private def build_union(cursor : Clang::Cursor) : Type
    name = cursor.spelling || ""
    raise error("No union name", cursor) if name.blank?

    if name.includes?("unnamed") || name.includes?("anonymous")
      if name2 = @unnamed_types_map[name]?
        name = name2
      else
        name2 = "__inline_type_#{source.name}_#{@unnamed_types_map.size}"
        @unnamed_types_map[name] = name2
        name = name2
      end
    end

    case enum_type = typer.map[name]? || mod.type_defs[name]?.try(&.type)
    when Type::EnumType
    when Nil
      enum_type = Type::EnumType.new(location(cursor), name, nil)
      node = cursor_to_node(cursor)
      mod.type_defs[name] = Mod::TypeDef.new(@mod, node, enum_type)
      typer.map[name] = enum_type
    else
      raise error("Type #{name} already defined as #{enum_type.class}, but expected union", cursor)
    end

    return enum_type unless enum_type.data.empty?

    fields = [] of {String, Type}

    children(cursor).each do |child|
      case child.kind
      when .field_decl?
        field_name = child.spelling
        field_type = get_type(child, child.type)
        fields << {field_name, field_type}
      when .struct_decl?
        if child.spelling.includes?("anonymous")
          fields << {"__mycc_anon_field__#{fields.size}", build_struct_decl(child)}
        end
      when .union_decl?
        if child.spelling.includes?("anonymous")
          fields << {"__mycc_anon_field__#{fields.size}", build_union(child)}
        end
      when .packed_attr?
        enum_type.explicit_alignment = 1_u64
      when .aligned_attr?
        puts "warning ignore aligned attr for #{name}"
      else
        raise error("Unhandled child: #{child.kind}", child)
      end
    end

    @unions[name] = fields

    fields.each do |(field_name, field_type)|
      variant = Type::EnumVariantType.new(
        location(cursor),
        "#{name}::#{field_name}",
        field_name,
        enum_type,
        enum_type.data.size
      )
      variant.value_types << field_type
      variant.hidden = true
      enum_type.data[variant.id_name] = variant
      typer.map[variant.id_name] = variant

      ct = Type::StructType.new(location(cursor), variant.id_name + "::__value_type__")
      ct.hidden = true
      ct.data = [field_type]
      variant.composite_value_type = ct
    end

    if (f = @shared_types.struct_fields[name]?) && !f.empty?
    else
      @shared_types.struct_fields[name] = fields
    end

    enum_type
  end

  private def build_enum(cursor : Clang::Cursor)
    name = cursor.spelling

    cursor.visit_children do |child|
      if child.kind.enum_constant_decl?
        const_name = child.spelling
        const_value = child.enum_constant_decl_value
        @enum_values[const_name] = const_value
      else
        raise error("Unhandled child: #{child.kind}", child)
      end
      Clang::ChildVisitResult::Continue
    end

    unless name.empty?
      @enum_types[name] = typer.i32
    end
  end

  private def build_node(cursor : Clang::Cursor) : TypedAST::Node
    case cursor.kind
    when .integer_literal?      then build_int_literal(cursor)
    when .floating_literal?     then build_float_literal(cursor)
    when .character_literal?    then build_char_literal(cursor)
    when .string_literal?       then build_string_literal(cursor)
    when .decl_ref_expr?        then build_var_ref(cursor)
    when .call_expr?            then build_call(cursor)
    when .unary_operator?       then build_unary(cursor)
    when .c_style_cast_expr?    then build_cast(cursor)
    when .array_subscript_expr? then build_subscript(cursor)
    when .unary_expr?           then build_sizeof(cursor)
    when .init_list_expr?       then build_init_list(cursor)
    when .member_ref_expr?
      field_name = cursor.spelling

      if field_name.includes?("anonymous") || field_name.includes?("unnamed")
        children_list = children(cursor)
        if children_list.size > 0
          build_node(children_list[0])
        else
          raise error("empty anonymous field", cursor)
        end
      else
        build_field(cursor)
      end
    when .conditional_operator?  then build_conditional(cursor)
    when .compound_literal_expr? then build_compound_literal(cursor)
    when .binary_operator?
      op = cursor.spelling
      if op == ","
        children_list = children(cursor)
        left = build_node(children_list[0])
        right = build_node(children_list[1])
        TypedAST::BinaryOp.new(:comma, left, right, right.type, location(cursor))
      elsif op == "="
        children_list = children(cursor)
        left = build_node(children_list[0])
        right = build_node(children_list[1])
        right = auto_cast(right, left.type, location(cursor))
        mark_param_changed(left)
        TypedAST::AssignExpr.new(left, right, location(cursor))
      else
        build_binary(cursor)
      end
    when .first_expr?
      if literal = try_evaluate(cursor)
        return literal
      end

      children = children(cursor)
      children.size == 1 ? build_node(children[0]) : raise error("Unknown node #{cursor.kind}", cursor)
    when .paren_expr?
      children = children(cursor)
      children.size == 1 ? build_node(children[0]) : raise error("Unknown node #{cursor.kind}", cursor)
    when .compound_assign_operator?
      op = cursor.spelling
      children_list = children(cursor)
      left = build_node(children_list[0])
      right = build_node(children_list[1])
      right = auto_cast(right, left.type, location(cursor))

      base_op = op.ends_with?('=') ? op[0..-2] : op
      bin_op = BINARY_MAP[base_op]? || raise error("Unknown op: #{base_op}", cursor)
      TypedAST::BinaryOp.new(bin_op, left, right, left.type, location(cursor))
    else
      raise error("Unknown node #{cursor.kind}", cursor)
    end
  end

  private def build_stmt(cursor : Clang::Cursor, body : Array(TypedAST::Stmt))
    case cursor.kind
    when .compound_stmt?
      block_body = [] of TypedAST::Stmt
      children(cursor).each { |child| build_stmt(child, block_body) }
      body << TypedAST::Block.new(block_body, location(cursor))
    when .call_expr?
      expr = build_call(cursor)
      body << TypedAST::ExprStmt.new(expr, location(cursor))
    when .decl_stmt?
      children(cursor).each do |child|
        if child.kind.var_decl?
          body << build_var_decl(child)
        elsif child.kind.struct_decl?
          build_struct_decl(child)
        elsif child.kind.union_decl?
          build_union(child)
        elsif child.kind.enum_decl?
          build_enum(child)
        elsif child.kind.typedef_decl?
          type_name = child.spelling
          underlying_type = get_type(child, child.typedef_decl_underlying_type)
          unless mod.type_defs[type_name]? || typer.map[type_name]?
            mod.type_defs[type_name] = Mod::TypeDef.new(@mod, cursor_to_node(child), underlying_type)
            typer.map[type_name] = underlying_type
          end
        else
          raise error("Unhandled child: #{child.kind}", child)
        end
      end
    when .return_stmt?
      body << build_return(cursor)
    when .if_stmt?
      body << build_if(cursor)
    when .while_stmt?
      body << build_while(cursor)
    when .do_stmt?
      body << build_do_while(cursor)
    when .for_stmt?
      body << build_for(cursor)
    when .switch_stmt?
      body << build_switch(cursor)
    when .paren_expr?, .first_expr?
      children_list = children(cursor)
      if children_list.size == 1
        child = children_list[0]
        build_stmt(child, body)
      else
        raise error("unexpected #{cursor.kind} with #{children_list.size} children", cursor)
      end
    when .binary_operator?
      op = cursor.spelling
      if op == ","
        stmts = [] of TypedAST::Stmt
        collect_comma_stmts(cursor, stmts)
        body << TypedAST::Block.new(stmts, location(cursor))
      elsif op == "="
        children_list = children(cursor)
        left = build_node(children_list[0])
        right = build_node(children_list[1])
        right = auto_cast(right, left.type, location(cursor))
        mark_param_changed(left)
        body << TypedAST::Assign.new(left, right, location(cursor))
      else
        expr = build_binary(cursor)
        body << TypedAST::ExprStmt.new(expr, location(cursor))
      end
    when .unary_operator?
      op = detect_unary_op(cursor)
      if op == "++" || op == "--"
        expr = build_unary(cursor, is_statement: true, known_op: op)
        body << TypedAST::ExprStmt.new(expr, location(cursor))
      else
        expr = build_unary(cursor, known_op: op)
        body << TypedAST::ExprStmt.new(expr, location(cursor))
      end
    when .break_stmt?
      case state = @break_stack.last?
      when TypedAST::Switch
        body << TypedAST::Goto.new(state.label_prefix + "_end", location(cursor))
      when Nil
        raise error("unexpected break", cursor)
      else
        body << TypedAST::Break.new(location(cursor))
      end
    when .continue_stmt?
      body << TypedAST::Continue.new(location(cursor))
    when .goto_stmt?
      label_name = ""
      children(cursor).each do |child|
        if child.kind.label_ref?
          label_name = child.spelling
        else
          raise error("Unhandled child: #{child.kind}", child)
        end
      end
      body << TypedAST::Goto.new(label_name, location(cursor))
    when .compound_assign_operator?
      op = cursor.spelling
      children_list = children(cursor)
      left = build_node(children_list[0])
      right = build_node(children_list[1])
      right = auto_cast(right, left.type, location(cursor))
      mark_param_changed(left)
      base_op = op.ends_with?('=') ? op[0..-2] : op
      bin_op = BINARY_MAP[base_op]? || :add
      value = TypedAST::BinaryOp.new(bin_op, left.dup, right, left.type, location(cursor))
      body << TypedAST::Assign.new(left, value, location(cursor))
    when .c_style_cast_expr?
      target_type = get_type(cursor, cursor.type)
      if target_type.id_name == "void"
        children_list = children(cursor)
        if children_list.size > 0
          expr_node = build_node(children_list.last)
          body << TypedAST::ExprStmt.new(expr_node, location(cursor))
        else
          raise error("void cast without expression", cursor)
        end
      else
        expr = build_cast(cursor)
        body << TypedAST::ExprStmt.new(expr, location(cursor))
      end
    when .integer_literal?, .floating_literal?, .character_literal?, .string_literal?,
         .decl_ref_expr?, .member_ref_expr?, .array_subscript_expr?
      node = build_node(cursor)
      body << TypedAST::ExprStmt.new(node, location(cursor))
    when .conditional_operator?
      node = build_conditional(cursor)
      body << TypedAST::ExprStmt.new(node, location(cursor))
    when .null_stmt?
      body << TypedAST::Block.new([] of TypedAST::Stmt, location(cursor))
    when .label_stmt?
      body << TypedAST::Label.new(cursor.spelling, location(cursor))
      children(cursor).each { |child| build_stmt(child, body) }
    when .var_decl?
      body << build_var_decl(cursor)
    when .label_ref?
    else
      raise error("Unhandled stmt #{cursor.kind}", cursor)
    end
  end

  private def collect_comma_stmts(cursor : Clang::Cursor, body : Array(TypedAST::Stmt))
    if cursor.kind.binary_operator? && cursor.spelling == ","
      children_list = children(cursor)
      collect_comma_stmts(children_list[0], body)
      collect_comma_stmts(children_list[1], body)
    elsif cursor.kind.paren_expr?
      children(cursor).each do |child|
        collect_comma_stmts(child, body)
      end
    else
      build_body(cursor, body)
    end
  end

  private def build_return(cursor : Clang::Cursor) : TypedAST::Return
    value = nil
    children(cursor).each do |child|
      node = build_node(child)
      value = node
    end
    if value && (ctr = @current_return_type)
      value = auto_cast(value, ctr, location(cursor))
    end
    TypedAST::Return.new(value, location(cursor))
  end

  private def build_var_decl(cursor : Clang::Cursor) : TypedAST::VarDecl
    name = cursor.spelling
    var_type = get_type(cursor, cursor.type)
    is_static = cursor.storage_class.static?
    is_vla = cursor.type.canonical_type.kind.variable_array?
    is_extern = cursor.storage_class.extern? && !is_static

    init = nil

    if !init && (literal = try_evaluate(cursor))
      init = literal
    end

    if is_vla
      children(cursor).each do |child|
        unless child.kind.parm_decl? || child.kind.type_ref?
          size_node = build_node(child)
          init = size_node
        end
      end
    end

    unless init
      children(cursor).each do |child|
        unless child.kind.parm_decl? || child.kind.type_ref? ||
               child.kind.struct_decl? || child.kind.union_decl? ||
               child.kind.enum_decl? || child.kind.visibility_attr? ||
               child.kind.asm_label_attr?
          node = build_node(child)
          init = node
        end
      end

      if init
        if init.is_a?(TypedAST::InitList) && init.elements.size > 0
          all_zeros = init.elements.all? { |elem| elem.is_a?(TypedAST::IntLiteral) && elem.value == 0 }
          if all_zeros
            init = TypedAST::ZeroInitializer.new(var_type, location(cursor))
          end
        end
        if var_type.is_a?(Type::FlatType) && init.is_a?(TypedAST::IntLiteral)
          init = nil
        elsif var_type.is_a?(Type::FlatType) && init.is_a?(TypedAST::StringLiteral)
        elsif init.is_a?(TypedAST::InitList)
          init = resolve_init_list_types(init, var_type)
          init = auto_cast(init, var_type, location(cursor)) if init.type != var_type
        elsif init.is_a?(TypedAST::ZeroInitializer)
        else
          init = auto_cast(init, var_type, location(cursor))
        end
      end
    end

    if (is_static || @current_function_name.empty?) && !is_extern
      if init.nil? || (init.is_a?(TypedAST::Cast) && is_zero_cast?(init))
        if var_type.is_a?(Type::FlatType) || var_type.is_a?(Type::StructType)
          init = TypedAST::ZeroInitializer.new(var_type, location(cursor))
        else
          init = TypedAST::IntLiteral.new(0_i64, var_type, location(cursor))
        end
      end
    end

    if is_static
      func_name = @current_function_name.presence || "static_#{source.name}"
      unique_name = "#{func_name}_#{name}"
      var = TypedAST::VarDecl.new(unique_name, var_type, init, location(cursor), is_static: true, is_vla: is_vla, original_name: name)
      unless @globals.any? { |g| g.name == unique_name }
        @globals << var
      end
      var
    elsif @current_function_name.empty?
      var = TypedAST::VarDecl.new(name, var_type, init, location(cursor), is_extern: is_extern && init.nil?, is_vla: is_vla)
      if var_found = @globals.find { |g| g.name == var.name }
        if var_found.is_extern && !var.is_extern
          @globals.delete(var_found)
          @globals << var
        end
      else
        @globals << var
      end
      var
    else
      TypedAST::VarDecl.new(name, var_type, init, location(cursor), is_vla: is_vla)
    end
  end

  private def get_field_types(type : Type?) : Array(Type)
    case type
    when Type::StructType
      type.data
    when Type::FlatType
      type.elements_count.times.map { type.target_type }.to_a
    else
      [] of Type
    end
  end

  private def is_zero_cast?(node : TypedAST::Node) : Bool
    case node
    when TypedAST::Cast
      is_zero_cast?(node.operand)
    when TypedAST::IntLiteral
      node.value == 0
    else
      false
    end
  end

  private def resolve_init_list_types(init_list : TypedAST::InitList, target_type : Type) : TypedAST::InitList
    elements = [] of TypedAST::Node
    field_types = if target_type.is_a?(Type::StructType)
                    target_type.data
                  elsif target_type.is_a?(Type::FlatType)
                    target_type.elements_count.times.map { target_type.target_type }.to_a
                  else
                    [] of Type
                  end

    init_list.elements.each_with_index do |elem, idx|
      if elem.is_a?(TypedAST::InitList) && elem.type.id_name == "void"
        nested_type = field_types[idx]? || target_type
        elements << resolve_init_list_types(elem, nested_type)
      else
        expected_type = field_types[idx]?
        if expected_type
          elements << auto_cast(elem, expected_type, elem.location)
        else
          elements << elem
        end
      end
    end

    (elements.size...field_types.size).each do |idx|
      expected_type = field_types[idx]
      zero = TypedAST::IntLiteral.new(0_i64, expected_type, init_list.location)
      elements << auto_cast(zero, expected_type, zero.location)
    end

    TypedAST::InitList.new(elements, target_type, init_list.location)
  end

  private def build_if(cursor : Clang::Cursor) : TypedAST::If
    children_list = children(cursor)
    condition = ensure_bool(build_node(children_list[0]))
    then_body = [] of TypedAST::Stmt
    build_body(children_list[1], then_body) if children_list.size > 1
    else_body = [] of TypedAST::Stmt
    build_body(children_list[2], else_body) if children_list.size > 2
    TypedAST::If.new(condition, then_body, else_body, location(cursor))
  end

  private def ensure_bool(node : TypedAST::Node) : TypedAST::Node
    node = auto_decay(node)
    return node if node.type.is_a?(Type::BoolType)

    loc = node.location

    if node.type.is_a?(Type::PtrType)
      zero = auto_cast(TypedAST::IntLiteral.new(0_i64, typer.i32, loc), node.type, loc)
      TypedAST::BinaryOp.new(:not_eq, node, zero, typer.bool, loc)
    elsif node.type.is_a?(Type::FloatType)
      zero = TypedAST::FloatLiteral.new(0.0, node.type, loc)
      TypedAST::BinaryOp.new(:not_eq, node, zero, typer.bool, loc)
    else
      zero = TypedAST::IntLiteral.new(0_i64, node.type, loc)
      TypedAST::BinaryOp.new(:not_eq, node, zero, typer.bool, loc)
    end
  end

  private def build_call(cursor : Clang::Cursor) : TypedAST::Call
    func_name = cursor.spelling
    children_list = children(cursor)

    callee = children_list.find do |c|
      if c.kind.decl_ref_expr?
        c.spelling == func_name
      elsif c.kind.member_ref_expr?
        c.spelling == func_name
      elsif c.kind.first_expr?
        children(c).any? { |inner|
          (inner.kind.decl_ref_expr? || inner.kind.member_ref_expr?) && inner.spelling == func_name
        }
      else
        false
      end
    end
    is_invoke = !!(func_name.empty? || (callee && is_variable_callee?(callee, func_name)))

    param_types = get_param_types(cursor, func_name, is_invoke)

    if is_invoke
      args = [] of TypedAST::Node
      callee_node = if func_name.empty?
                      node = build_node(children_list[0])
                      args = children_list[1..].map { |c| build_node(c) }
                      node
                    elsif callee
                      node = build_node(callee)
                      args = children_list.reject { |c| c == callee }.map { |c| build_node(c) }
                      node
                    else
                      raise error("bad invoke", cursor)
                    end
      ret_type = get_type(cursor, cursor.type)

      if param_types
        all_args = [callee_node] + args
        param_types.each_with_index do |pt, i|
          all_args[i + 1] = auto_cast(all_args[i + 1], pt, location(cursor))
        end

        args = all_args[1..]
        callee_node = all_args[0]
      end

      args.each_with_index do |arg, i|
        args[i] = auto_decay(arg)
      end

      vaargs_count = param_types ? args.size - param_types.size : 0
      TypedAST::Call.new("", [callee_node] + args, ret_type, location(cursor), is_invoke: true, vaargs_count: vaargs_count)
    else
      args = [] of TypedAST::Node

      children(cursor).each do |child|
        next if child.kind.decl_ref_expr? && child.spelling == func_name
        node = build_node(child)
        next if node.is_a?(TypedAST::VarRef) && node.name == func_name
        args << node
      end

      if param_types
        param_types.each_with_index do |pt, i|
          args[i] = auto_cast(args[i], pt, location(cursor))
        end
      end

      ret_type = get_type(cursor, cursor.type)
      args.each_with_index do |arg, i|
        args[i] = auto_decay(arg)
      end

      vaargs_count = param_types ? args.size - param_types.size : 0
      @called_functions << func_name
      TypedAST::Call.new(func_name, args, ret_type, location(cursor), vaargs_count: vaargs_count)
    end
  end

  private def get_param_types(cursor : Clang::Cursor, func_name : String, is_invoke : Bool) : Array(Type)?
    return nil if func_name.empty? && !is_invoke

    if is_invoke
      children_list = children(cursor)
      callee = children_list[0]?
      if callee
        callee_type = get_type(callee, callee.type)
        if callee_type.is_a?(Type::PtrType) && callee_type.target_type.is_a?(Type::Fn)
          return callee_type.target_type.as(Type::Fn).args
        elsif callee_type.is_a?(Type::Fn)
          return callee_type.args
        end
      end
      return nil
    end

    callee_cursor = find_callee_decl(cursor, func_name)
    if callee_cursor
      func_type = get_type(callee_cursor, callee_cursor.type)
      if func_type.is_a?(Type::Fn)
        return func_type.args
      end
    end

    nil
  end

  private def find_callee_decl(cursor : Clang::Cursor, func_name : String) : Clang::Cursor?
    children(cursor).each do |child|
      if child.kind.decl_ref_expr? && child.spelling == func_name
        return child.referenced
      elsif child.kind.first_expr?
        found = find_callee_decl(child, func_name)
        return found if found
      else
        raise error("Unhandled child: #{child.kind}", child)
      end
    end
    nil
  end

  private def build_compound_literal(cursor : Clang::Cursor) : TypedAST::Node
    target_type = get_type(cursor, cursor.type)

    node = nil
    cursor.visit_children do |child|
      if child.kind.init_list_expr?
        node = build_init_list(child, target_type)
        Clang::ChildVisitResult::Break
      else
        Clang::ChildVisitResult::Continue
      end
    end

    if node
      return node.as(TypedAST::Node)
    else
      raise error("cant build_compound_literal", cursor)
    end
  end

  private def build_binary(cursor : Clang::Cursor) : TypedAST::Node
    if literal = try_evaluate(cursor)
      return literal
    end

    op = cursor.spelling
    if op.empty?
      @tu.tokenize(cursor.extent) do |token|
        if !token.spelling.empty? && BINARY_MAP.has_key?(token.spelling)
          op = token.spelling
          break
        end
      end
    end

    children_list = children(cursor)
    left = build_node(children_list[0])
    right = build_node(children_list[1])
    left = auto_decay(left)
    right = auto_decay(right)
    loc = location(cursor)

    case op
    when "&&", "||"
      left = ensure_bool(left)
      right = ensure_bool(right)
      op_name = BINARY_MAP[op]?
      raise error("unknown binary #{op}", cursor) unless op_name
      result = TypedAST::BinaryOp.new(op_name, left, right, typer.bool, loc)
    when "<", ">", "<=", ">=", "==", "!="
      op_name = BINARY_MAP[op]?
      raise error("unknown binary #{op}", cursor) unless op_name

      if left.type.is_a?(Type::PtrType) && right.type.is_a?(Type::PtrType)
        left = TypedAST::Cast.new(left, typer.u64, loc)
        right = TypedAST::Cast.new(right, typer.u64, loc)
        result = TypedAST::BinaryOp.new(op_name, left, right, typer.bool, loc)
      else
        common = common_type(left.type, right.type)
        left = auto_cast(left, common, loc)
        right = auto_cast(right, common, loc)
        result = TypedAST::BinaryOp.new(op_name, left, right, typer.bool, loc)
      end
    else
      op_name = BINARY_MAP[op]?
      raise error("unknown binary #{op}", cursor) unless op_name

      left = auto_cast(left, typer.i32, loc) if left.type.is_a?(Type::BoolType)
      right = auto_cast(right, typer.i32, loc) if right.type.is_a?(Type::BoolType)
      if left.type.is_a?(Type::PtrType) && right.type.is_a?(Type::PtrType) && op_name == :sub
        TypedAST::BinaryOp.new(:sub, left, right, typer.i64, loc)
      elsif left.type.is_a?(Type::PtrType) && right.type.is_a?(Type::IntType)
        right = auto_cast(right, typer.u64, loc)
        TypedAST::BinaryOp.new(op_name, left, right, left.type, loc)
      elsif right.type.is_a?(Type::PtrType) && left.type.is_a?(Type::IntType)
        left = auto_cast(left, typer.u64, loc)
        TypedAST::BinaryOp.new(op_name, left, right, right.type, loc)
      elsif left.type.is_a?(Type::FlatType) && right.type.is_a?(Type::IntType)
        elem_type = left.type.as(Type::FlatType).target_type
        ptr_type = typer.to_ptr(elem_type, loc)
        left = auto_cast(left, ptr_type, loc)
        right = auto_cast(right, typer.u64, loc)
        TypedAST::BinaryOp.new(op_name, left, right, ptr_type, loc)
      else
        common = common_type(left.type, right.type)
        left = auto_cast(left, common, loc)
        right = auto_cast(right, common, loc)
        TypedAST::BinaryOp.new(op_name, left, right, common, loc)
      end
    end
  end

  private def build_unary(cursor : Clang::Cursor, is_statement : Bool = false, known_op : String? = nil) : TypedAST::Node
    if literal = try_evaluate(cursor)
      return literal
    end

    op = known_op || detect_unary_op(cursor)

    children_list = children(cursor)
    operand = children_list.size > 0 ? build_node(children_list[0]) : raise error("unary no child", cursor)
    loc = location(cursor)

    case op
    when "-"
      TypedAST::UnaryOp.new(:neg, operand, operand.type, loc)
    when "!"
      if operand && operand.type.is_a?(Type::PtrType)
        zero = auto_cast(TypedAST::IntLiteral.new(0_i64, typer.i32, loc), operand.type, loc)
        TypedAST::BinaryOp.new(:eq, operand, zero, typer.bool, loc)
      elsif operand && operand.type.is_a?(Type::BoolType)
        TypedAST::UnaryOp.new(:lnot, operand, typer.bool, loc)
      else
        zero = TypedAST::IntLiteral.new(0_i64, operand.type, loc)
        TypedAST::BinaryOp.new(:eq, operand, zero, typer.bool, loc)
      end
    when "~"
      TypedAST::UnaryOp.new(:bnot, operand, operand.type, loc)
    when "*"
      operand = auto_decay(operand)
      type = operand.type
      if type.is_a?(Type::PtrType)
        TypedAST::Deref.new(operand, type.target_type, loc)
      elsif type.is_a?(Type::Fn)
        operand
      else
        raise error("Cannot dereference non-pointer type #{type}", cursor)
      end
    when "&"
      if operand && operand.type.is_a?(Type::Fn)
        operand
      else
        ptr_type = typer.to_ptr(operand.type, loc)
        TypedAST::AddrOf.new(operand, ptr_type, loc)
      end
    when "++", "--"
      is_inc = op == "++"
      is_prefix = is_prefix_unary?(cursor)

      op_sym = case {is_inc, is_prefix}
               when {true, true}   then :prefix_inc
               when {true, false}  then :postfix_inc
               when {false, true}  then :prefix_dec
               when {false, false} then :postfix_dec
               else
                 raise "unreachable"
               end

      mark_param_changed(operand)

      op_type = is_statement ? typer.void : operand.type
      TypedAST::UnaryOp.new(op_sym, operand, op_type, loc, is_statement)
    else
      raise error("Unknown unary operator: #{op}", cursor)
    end
  end

  def detect_unary_op(cursor : Clang::Cursor) : String
    op = cursor.spelling
    return op unless op.empty?

    case cursor.unary_operator_kind
    when LibC::CXUnaryOperatorKind::AddrOf  then "&"
    when LibC::CXUnaryOperatorKind::Deref   then "*"
    when LibC::CXUnaryOperatorKind::Minus   then "-"
    when LibC::CXUnaryOperatorKind::LNot    then "!"
    when LibC::CXUnaryOperatorKind::Not     then "~"
    when LibC::CXUnaryOperatorKind::PostInc then "++"
    when LibC::CXUnaryOperatorKind::PostDec then "--"
    when LibC::CXUnaryOperatorKind::PreInc  then "++"
    when LibC::CXUnaryOperatorKind::PreDec  then "--"
    else
      raise error("unknown unary_op", cursor)
    end
  end

  private def build_init_list(cursor : Clang::Cursor, target_type : Type? = nil) : TypedAST::InitList
    elements = [] of TypedAST::Node
    field_types = get_field_types(target_type)
    field_idx = 0

    children(cursor).each do |child|
      if child.kind.init_list_expr?
        nested_type = field_types[field_idx]? || typer.void
        elements << build_init_list(child, nested_type)
        field_idx += 1
      else
        node = build_node(child)
        expected_type = field_types[field_idx]?
        if expected_type
          node = auto_cast(node, expected_type, node.location)
        end
        elements << node
        field_idx += 1
      end
    end

    type = target_type || typer.void
    TypedAST::InitList.new(elements, type, location(cursor))
  end

  private def build_while(cursor : Clang::Cursor) : TypedAST::While
    children_list = children(cursor)
    condition = ensure_bool(build_node(children_list[0]))
    w = TypedAST::While.new(condition, [] of TypedAST::Stmt, location(cursor))
    @break_stack << w
    build_body(children_list[1], w.body) if children_list.size > 1
    @break_stack.pop
    w
  end

  private def build_do_while(cursor : Clang::Cursor) : TypedAST::DoWhile
    children_list = children(cursor)

    condition = if children_list.size > 1
                  ensure_bool(build_node(children_list[1]))
                else
                  raise error("No condition", cursor)
                end
    dw = TypedAST::DoWhile.new(condition, [] of TypedAST::Stmt, location(cursor))
    @break_stack << dw
    build_body(children_list[0], dw.body) if children_list.size > 0
    @break_stack.pop
    dw
  end

  private def build_for(cursor : Clang::Cursor) : TypedAST::For
    children_list = children(cursor)

    semicolon_count = 0
    tokens_after_open = 0
    tokens_after_first_semi = 0
    tokens_after_second_semi = 0
    found_open = false

    @tu.tokenize(cursor.extent) do |token|
      sp = token.spelling

      if sp == "("
        found_open = true
        next
      end

      next unless found_open

      case sp
      when ";"
        semicolon_count += 1
      else
        case semicolon_count
        when 0 then tokens_after_open += 1
        when 1 then tokens_after_first_semi += 1
        when 2 then tokens_after_second_semi += 1
        end
      end

      break if semicolon_count >= 2 && tokens_after_second_semi > 0 && sp == ")"
    end

    has_init = tokens_after_open > 0
    has_cond = tokens_after_first_semi > 0
    has_step = tokens_after_second_semi > 0

    if !has_init && !has_cond && !has_step
      if children_list.size == 4
        has_init = true
        has_cond = true
        has_step = true
      else
        raise error("cant parse for #{children_list.size} childs", cursor)
      end
    end

    parts = children_list[...-1]
    init = Array(TypedAST::Stmt).new
    condition = nil
    update = Array(TypedAST::Stmt).new

    part_idx = 0

    if has_init && part_idx < parts.size
      build_body(parts[part_idx], init)
      part_idx += 1
    end

    if has_cond && part_idx < parts.size
      node = build_node(parts[part_idx])
      condition = ensure_bool(node)
      part_idx += 1
    end

    if has_step && part_idx < parts.size
      build_stmt(parts[part_idx], update)
      part_idx += 1
    end

    f = TypedAST::For.new(init, condition, update, [] of TypedAST::Stmt, location(cursor))
    @break_stack << f
    build_body(children_list.last, f.body)
    @break_stack.pop
    f
  end

  private def build_string_literal(cursor : Clang::Cursor) : TypedAST::StringLiteral
    raw = cursor.spelling
    unquoted = raw[1..-2]

    value = String.build do |str|
      i = 0
      while i < unquoted.size
        if unquoted[i] == '\\' && i + 1 < unquoted.size
          case unquoted[i + 1]
          when 'n'  then str << '\n'
          when 't'  then str << '\t'
          when 'r'  then str << '\r'
          when '\\' then str << '\\'
          when '"'  then str << '"'
          when '\'' then str << '\''
          when '0'
            if i + 3 < unquoted.size && unquoted[i + 2].in?('0'..'7') && unquoted[i + 3].in?('0'..'7')
              str << unquoted[i + 1..i + 3].to_i(8).chr
              i += 3
              next
            else
              str << '\0'
            end
          when 'x'
            if i + 3 < unquoted.size
              str << unquoted[i + 2..i + 3].to_i(16).chr
              i += 3
              next
            end
          else
            str << unquoted[i + 1]
          end
          i += 2
        else
          str << unquoted[i]
          i += 1
        end
      end
    end

    TypedAST::StringLiteral.new(value, typer.u8p, location(cursor))
  end

  private def build_int_literal(cursor : Clang::Cursor) : TypedAST::IntLiteral
    value = cursor.evaluate.try(&.as_long_long) || 0_i64
    type = get_type(cursor, cursor.type)
    TypedAST::IntLiteral.new(value, type, location(cursor))
  end

  private def build_float_literal(cursor : Clang::Cursor) : TypedAST::FloatLiteral
    value = cursor.evaluate.try(&.as_double) || 0.0
    type = get_type(cursor, cursor.type)
    TypedAST::FloatLiteral.new(value, type, location(cursor))
  end

  private def build_char_literal(cursor : Clang::Cursor) : TypedAST::CharLiteral
    value = cursor.evaluate.try(&.as_long_long.to_i) || 0
    type = get_type(cursor, cursor.type)
    TypedAST::CharLiteral.new(value, type, location(cursor))
  end

  private def build_conditional(cursor : Clang::Cursor) : TypedAST::Node
    children_list = children(cursor)
    condition = ensure_bool(build_node(children_list[0]))
    then_expr = build_node(children_list[1])
    else_expr = build_node(children_list[2])
    common = common_type(then_expr.type, else_expr.type)
    then_expr2 = auto_cast(then_expr, common, location(cursor))
    else_expr2 = auto_cast(else_expr, common, location(cursor))
    TypedAST::Conditional.new(condition, then_expr2, else_expr2, common, location(cursor))
  end

  private def build_var_ref(cursor : Clang::Cursor) : TypedAST::Node
    name = cursor.spelling
    type = get_type(cursor, cursor.type)
    if @current_function_params.has_key?(name) && type.is_a?(Type::FlatType)
      type = typer.to_ptr(type.target_type, location(cursor))
    end
    if @enum_values.has_key?(name)
      value = @enum_values[name]
      return TypedAST::IntLiteral.new(value, typer.i32, location(cursor))
    end
    @called_functions << name if type.is_a?(Type::Fn)
    TypedAST::VarRef.new(name, type, location(cursor))
  end

  private def is_prefix_unary?(cursor : Clang::Cursor) : Bool
    case cursor.unary_operator_kind
    when LibC::CXUnaryOperatorKind::PreInc, LibC::CXUnaryOperatorKind::PreDec
      true
    when LibC::CXUnaryOperatorKind::PostInc, LibC::CXUnaryOperatorKind::PostDec,
         LibC::CXUnaryOperatorKind::AddrOf, LibC::CXUnaryOperatorKind::Deref,
         LibC::CXUnaryOperatorKind::Minus, LibC::CXUnaryOperatorKind::LNot,
         LibC::CXUnaryOperatorKind::Not
      false
    else
      raise error("Unknown unary operator kind: #{cursor.unary_operator_kind}", cursor)
    end
  end

  private def build_cast(cursor : Clang::Cursor) : TypedAST::Node
    target_type = get_type(cursor, cursor.type)

    children_list = children(cursor)
    operand = build_node(children_list.last)
    operand = auto_decay(operand)

    from = operand.type
    if (from.is_a?(Type::PtrType) || from.is_a?(Type::Fn)) && target_type.is_a?(Type::IntType)
      operand = TypedAST::Cast.new(operand, typer.u64, location(cursor))
    end

    TypedAST::Cast.new(operand, target_type, location(cursor))
  end

  private def build_subscript(cursor : Clang::Cursor) : TypedAST::Subscript
    children_list = children(cursor)
    array = build_node(children_list[0])
    index = build_node(children_list[1])
    elem_type = case type = array.type
                when Type::PtrType  then type.target_type
                when Type::FlatType then type.target_type
                else                     array.type
                end
    index = auto_cast(index, typer.i64, location(cursor))
    TypedAST::Subscript.new(array, index, elem_type, location(cursor))
  end

  private def build_sizeof(cursor : Clang::Cursor) : TypedAST::Node
    case literal = try_evaluate(cursor)
    when TypedAST::IntLiteral
      return literal
    else
      children_list = children(cursor)
      if children_list.size > 0
        child = children_list[0]
        target_type = get_type(child, child.type)
        TypedAST::SizeOf.new(target_type, typer.u64, location(cursor))
      else
        target_type = get_type(cursor, cursor.type)
        TypedAST::SizeOf.new(target_type, typer.u64, location(cursor))
      end
    end
  end

  private def build_field(cursor : Clang::Cursor) : TypedAST::FieldAccess
    field_name = cursor.spelling
    children_list = children(cursor)
    obj = build_node(children_list[0])
    obj_type = obj.type

    if obj_type.is_a?(Type::PtrType)
      obj = TypedAST::Deref.new(obj, obj_type.as(Type::PtrType).target_type, location(cursor))
      obj_type = obj.type
    end

    if result = find_field_path(obj, obj_type, field_name, location(cursor))
      return result
    end

    raise error("field not found `#{field_name}` for type `#{obj_type.id_name}`", cursor)
  end

  private def find_field_path(obj : TypedAST::Node, obj_type : Type, field_name : String, loc : Location) : TypedAST::FieldAccess?
    if direct = find_direct_field(obj, obj_type, field_name, loc)
      return direct
    end

    anon_fields = get_anon_fields(obj_type)

    anon_fields.each do |(anon_name, anon_type, anon_index)|
      if obj_type.is_a?(Type::EnumType)
        variant = obj_type.data.values.find { |v| v.original_name == anon_name }
        if variant
          casted = TypedAST::Cast.new(obj, variant, loc)
          anon_obj = TypedAST::FieldAccess.new(casted, anon_name, 1, anon_type, loc)
        else
          anon_obj = TypedAST::FieldAccess.new(obj, anon_name, anon_index, anon_type, loc)
        end
      else
        anon_obj = TypedAST::FieldAccess.new(obj, anon_name, anon_index, anon_type, loc)
      end

      if found = find_field_path(anon_obj, anon_type, field_name, loc)
        return found
      end
    end

    nil
  end

  private def find_direct_field(obj : TypedAST::Node, obj_type : Type, field_name : String, loc : Location) : TypedAST::FieldAccess?
    case obj_type
    when Type::StructType
      if fields = @shared_types.struct_fields[obj_type.id_name]?
        if idx = fields.index { |name, _| name == field_name }
          field_type = obj_type.data[idx]
          return TypedAST::FieldAccess.new(obj, field_name, idx, field_type, loc)
        end
      end
    when Type::EnumType
      if variant = obj_type.data.values.find { |v| v.original_name == field_name }
        casted = TypedAST::Cast.new(obj, variant, loc)
        field_type = variant.value_types.first? || obj_type
        return TypedAST::FieldAccess.new(casted, field_name, 1, field_type, loc)
      end
    when Type::EnumVariantType
      if composite = obj_type.composite_value_type
        if found = find_direct_field(obj, composite, field_name, loc)
          return found
        end
      end
    end

    nil
  end

  private def get_anon_fields(obj_type : Type) : Array({String, Type, Int32})
    result = [] of {String, Type, Int32}

    case obj_type
    when Type::StructType
      if fields = @shared_types.struct_fields[obj_type.id_name]?
        fields.each_with_index do |(name, type), index|
          if name.starts_with?("__mycc_anon_field__")
            result << {name, type, index}
          end
        end
      end
    when Type::EnumType
      obj_type.data.each do |variant_name, variant|
        if variant.original_name.starts_with?("__mycc_anon_field__")
          anon_type = variant.value_types.first? || obj_type

          index = variant.position
          result << {variant.original_name, anon_type, index}
        end
      end
    end

    result
  end

  private def build_switch(cursor : Clang::Cursor) : TypedAST::Switch
    children_list = children(cursor)
    value = build_node(children_list[0])
    cases = [] of TypedAST::Case
    switch_label_prefix = "__switch_#{@switch_counter}"
    @switch_counter += 1
    sw = TypedAST::Switch.new(value, cases, location(cursor), switch_label_prefix)
    @break_stack << sw

    children(children_list[1]).each do |child|
      case child.kind
      when .case_stmt?
        label = "#{switch_label_prefix}_#{cases.size}"
        values = [extract_case_value(child)]
        body = [] of TypedAST::Stmt
        collect_case_values_and_body(child, values, body)
        cases << TypedAST::Case.new(values, body, location(child), label)
      when .default_stmt?
        label = "#{switch_label_prefix}_#{cases.size}"
        values = [] of Int64
        body = [] of TypedAST::Stmt
        collect_case_values_and_body(child, values, body)
        cases << TypedAST::Case.new(values, body, location(child), label)
      else
        if last_case = cases.last?
          build_body(child, last_case.body)
        else
          raise error("No cases: #{child.kind}", child)
        end
      end
    end

    @break_stack.pop
    sw
  end

  private def collect_case_values_and_body(cursor : Clang::Cursor, values, body : Array(TypedAST::Stmt))
    children(cursor).each do |child|
      case child.kind
      when .case_stmt?
        values << extract_case_value(child)
        collect_case_values_and_body(child, values, body)
      else
        build_body(child, body)
      end
    end
  end

  private def extract_case_value(cursor : Clang::Cursor) : Int64
    child = cursor.first_child?
    raise error("case without value", cursor) unless child

    if result = child.evaluate
      case result.kind
      when LibC::CXEvalResultKind::Int
        return result.as_long_long
      end
    end

    case child.kind
    when .decl_ref_expr?
      name = child.spelling
      @enum_values[name] || raise error("unknown enum value #{name}", cursor)
    when .paren_expr?, .first_expr?
      extract_case_value(child)
    else
      raise error("unexpected case value kind: #{child.kind}", cursor)
    end
  end

  private def common_type(t1 : Type, t2 : Type) : Type
    return t1 if t1 == t2
    return t1 if t1.is_a?(Type::PtrType) && t2.is_a?(Type::IntType)
    return t2 if t2.is_a?(Type::PtrType) && t1.is_a?(Type::IntType)
    return t1 if t1.is_a?(Type::FloatType)
    return t2 if t2.is_a?(Type::FloatType)
    if t1.is_a?(Type::IntType) && t2.is_a?(Type::IntType)
      return t1.bytes_count >= t2.bytes_count ? t1 : t2
    end
    t1
  end

  BINARY_MAP = {
    "+" => :add, "-" => :sub, "*" => :mul, "/" => :div,
    "<" => :less, ">" => :more, "<=" => :less_eq, ">=" => :more_eq,
    "==" => :eq, "!=" => :not_eq, "%" => :rem,
    "&&" => :land, "||" => :lor,
    "&" => :and, "|" => :or, "^" => :xor, "<<" => :shl, ">>" => :shr,
    "<<=" => :shl, ">>=" => :shr,
  }

  private def location(cursor : Clang::Cursor) : Location
    offset = if loc = cursor.location
               _, _, _, o = loc.file_location
               o
             else
               0
             end
    Location.new(source.filename, offset.to_u32)
  end

  private def cursor_to_node(cursor : Clang::Cursor) : Myc::Source::Node
    node = Myc::Source::Node.new(Opcode::Code::UNDEF)
    if loc = cursor.location
      _, _, _, offset = loc.file_location
      node.offset = offset
    else
      node.offset = 0
    end
    node
  end

  private def children(cursor : Clang::Cursor) : Array(Clang::Cursor)
    res = [] of Clang::Cursor
    cursor.visit_children do |child|
      res << child
      Clang::ChildVisitResult::Continue
    end
    res
  end

  private def get_type(cursor : Clang::Cursor, type : Clang::Type, count = 0) : Type
    count += 1
    canonical = type.canonical_type

    if count >= 50
      raise error("Recursion on get_type: #{canonical.kind} #{canonical.spelling}", cursor)
    end

    case canonical.kind
    when .void?                  then typer.void
    when .bool?                  then typer.bool
    when .char_s?                then typer.u8
    when .s_char?                then typer.i8
    when .char_u?, .u_char?      then typer.u8
    when .w_char?                then typer.u32
    when .short?                 then typer.i16
    when .int?                   then typer.i32
    when .u_short?               then typer.u16
    when .u_int?                 then typer.u32
    when .long?, .long_long?     then typer.i64
    when .u_long?, .u_long_long? then typer.u64
    when .u_int128?, .int128?    then typer.find("flat<i32, 4>", location(cursor))
    when .float?                 then typer.f32
    when .double?                then typer.f64
    when .long_double?           then typer.f64
    when .l_value_reference?
      get_type(cursor, canonical.pointee_type, count)
    when .variable_array?
      elem_type = get_type(cursor, canonical.array_element_type, count)
      typer.to_ptr(elem_type, location(cursor))
    when .block_pointer?
      typer.voidp
    when .pointer?
      pointee = get_type(cursor, canonical.pointee_type, count)
      if pointee.is_a?(Type::Fn)
        pointee
      else
        typer.to_ptr(get_type(cursor, canonical.pointee_type, count), location(cursor))
      end
    when .record?
      spelling = canonical.spelling
      spelling = spelling.sub("const ", "").sub("volatile ", "").sub("restrict ", "")
      name = spelling

      if name.starts_with?("union ")
        name2 = name.sub("union ", "")
        if type = (typer.map[name2]? || mod.type_defs[name2]?.try(&.type))
          return type
        end
      elsif name.starts_with?("struct ")
        name2 = name.sub("struct ", "")
        if type = (typer.map[name2]? || mod.type_defs[name2]?.try(&.type))
          return type
        end
      end

      type_cursor = canonical.cursor
      case type_cursor.kind
      when .union_decl?
        return build_union(type_cursor)
      when .struct_decl?
        return build_struct_decl(type_cursor)
      end

      raise error("unknown type #{name} #{type_cursor.kind}", cursor)
    when .constant_array?
      type_name = "flat<#{get_type(cursor, canonical.array_element_type, count)}, #{canonical.array_size}>"
      typer.find(type_name, location(cursor))
    when .incomplete_array?
      typer.to_ptr(get_type(cursor, canonical.array_element_type, count), location(cursor))
    when .elaborated?
      get_type(cursor, canonical.named_type, count)
    when .function_proto?
      ret = get_type(cursor, canonical.result_type, count)
      arg_types = canonical.arguments.map { |t| get_type(cursor, t, count) }
      vaarg = canonical.variadic?

      type_fn = Type::Fn.new(location(cursor), arg_types, ret, vaarg: vaarg)
      if existing = @typer.find_in_caches(type_fn.id_name)
        existing
      else
        @typer.map[type_fn.id_name] = type_fn
        type_fn
      end
    when .function_no_proto?
      ret = get_type(cursor, canonical.result_type, count)
      id_name = "fn<#{ret.id_name}>"
      typer.find(id_name, location(cursor))
    when .typedef?
      get_type(cursor, canonical.canonical_type, count)
    when .unexposed?
      if canonical.spelling.includes?("builtin")
        typer.voidp
      else
        raise error("UNKNOWN TYPE: #{canonical.kind} #{canonical.spelling}", cursor)
      end
    when .enum?
      name = canonical.spelling.sub("enum ", "")
      @enum_types[name]? || typer.i32
    else
      raise error("UNKNOWN TYPE: #{canonical.kind} #{canonical.spelling}", cursor)
    end
  end

  private def error(msg, cursor) : Myc::Error::ErrorLoc
    Myc::Error::ErrorLoc.new(msg, location(cursor), offset_in_bytes: true)
  end

  private def is_variable_callee?(cursor : Clang::Cursor, func_name : String) : Bool
    if cursor.kind.decl_ref_expr? && cursor.spelling == func_name
      return !cursor.referenced.kind.function_decl?
    elsif cursor.kind.member_ref_expr? && cursor.spelling == func_name
      return true
    elsif cursor.kind.first_expr?
      children(cursor).each do |inner|
        if inner.kind.decl_ref_expr? && inner.spelling == func_name
          return !inner.referenced.kind.function_decl?
        elsif inner.kind.member_ref_expr? && inner.spelling == func_name
          return true
        else
          raise error("Unhandled child: #{inner.kind}", inner)
        end
      end
    end
    false
  end

  private def mark_param_changed(node : TypedAST::VarRef)
    if param = @current_function_params[node.name]?
      param.changed = true
    end
  end

  private def mark_param_changed(node : TypedAST::Node)
  end

  private def auto_decay(node : TypedAST::Node) : TypedAST::Node
    if node.type.is_a?(Type::FlatType)
      flat_type = node.type.as(Type::FlatType)
      ptr_type = @typer.to_ptr(flat_type.target_type, node.location)
      addr = TypedAST::AddrOf.new(node, ptr_type, node.location)
      return TypedAST::Cast.new(addr, ptr_type, node.location)
    end
    node
  end

  enum SourceKind
    UserSource
    UserHeader
    SystemHeader
  end

  private def source_kind(cursor) : SourceKind
    return SourceKind::SystemHeader unless location = cursor.location
    filename = location.file_name
    return SourceKind::SystemHeader unless filename

    if filename.includes?(@source.filename)
      SourceKind::UserSource
    elsif filename.starts_with?("/Library/") ||
          filename.starts_with?("/usr/") ||
          filename.starts_with?("/opt/")
      SourceKind::SystemHeader
    else
      SourceKind::UserHeader
    end
  end

  private def try_evaluate(cursor : Clang::Cursor) : TypedAST::Node?
    if result = cursor.evaluate
      case result.kind
      when LibC::CXEvalResultKind::Int
        type = get_type(cursor, cursor.type)
        return TypedAST::IntLiteral.new(result.as_long_long, type, location(cursor))
      when LibC::CXEvalResultKind::Float
        type = get_type(cursor, cursor.type)
        return TypedAST::FloatLiteral.new(result.as_double, type, location(cursor))
      when LibC::CXEvalResultKind::StrLiteral
        type = get_type(cursor, cursor.type)
        return TypedAST::StringLiteral.new(result.as_str, type, location(cursor))
      end
    end
    nil
  end
end
