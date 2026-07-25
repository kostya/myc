class Myc::Mod
  def merge!(other : Mod, header : Bool)
    other.type_defs.each do |name, type_def|
      if t = @type_defs[name]?
        unless t.type.eq?(type_def.type)
          raise type_def.node.error("different type with same name #{name}: #{t.mod.filename} and #{other.filename}", other.filename)
        end
      else
        @type_defs[name] = type_def
      end
    end

    other.global_defs.each do |name, global_def|
      next if header && global_def.private_flag

      if g = @global_defs[name]?
        unless g.type.eq?(global_def.type)
          raise global_def.node.error("different global types with same name #{g.name}:#{g.type} vs #{name}:#{global_def.type}", other.filename)
        end

        case {g.initial_keyword, global_def.initial_keyword}
        when {true, true}
          raise global_def.node.error("double global #{name} definition with INITIAL: #{g.mod.filename} and #{other.filename}", other.filename)
        when {false, true}
          @global_defs[name] = global_def
        end
      else
        @global_defs[name] = global_def
      end
    end

    other.func_defs.each do |name, func_def|
      next if header && func_def.attrs.includes?(Mod::FuncDef::Attr::Private)

      if f = @func_defs[name]?
        unless f.type_fn.eq?(func_def.type_fn)
          raise func_def.node.error("different funcs with same name #{f.name}:#{f.type_fn} vs #{name}:#{func_def.type_fn}", other.filename)
        end

        case {!!f.body, !!func_def.body}
        when {true, true}
          if f.inline_stats.can_inline && func_def.inline_stats.can_inline
            unless f.body.not_nil!.list.size == func_def.body.not_nil!.list.size
              raise func_def.node.error("double func #{name} definition with BODY: #{f.mod.filename} and #{other.filename}", other.filename)
            end
          else
            raise func_def.node.error("double func #{name} definition with BODY: #{f.mod.filename} and #{other.filename}", other.filename)
          end
        when {false, true}
          @func_defs[name] = func_def
        end
      else
        @func_defs[name] = func_def
      end
    end
  end

  def clean_unused_types_and_globals
    used_globals = Set(String).new
    used_typedefs = Set(String).new

    @func_defs.each_value do |func_def|
      collect_type_deps(func_def.type_fn, used_typedefs)

      func_def.deep_walk do |op|
        case op
        when Opcode::Global
          used_globals << op.name
        when Opcode::Alloca, Opcode::As, Opcode::Create, Opcode::Local,
             Opcode::Malloc, Opcode::Push, Opcode::SizeOf, Opcode::To
          if t = op.type
            used_typedefs << t.id_name
          end
        end
      end
    end

    @global_defs.reject! do |name, global_def|
      !global_def.initial_keyword && !used_globals.includes?(name)
    end

    @global_defs.each do |_, global_def|
      collect_type_deps(global_def.type, used_typedefs)
    end

    unprocessed = used_typedefs.dup
    until unprocessed.empty?
      new_added = Set(String).new
      unprocessed.each do |used_name|
        if type_def = @type_defs[used_name]?
          deps = direct_type_dependencies(type_def.type)
          deps.each do |dep_type|
            dep_name = dep_type.id_name
            unless used_typedefs.includes?(dep_name)
              used_typedefs << dep_name
              new_added << dep_name
            end
          end
        end
      end
      unprocessed = new_added
    end

    @type_defs.select! { |name, _| used_typedefs.includes?(name) }
  end

  private def direct_type_dependencies(type : Type) : Array(Type)
    deps = [] of Type
    case type
    when Type::PtrType
      deps << type.target_type
    when Type::FlatType
      if tt = type.target_type
        deps << tt
      end
    when Type::EnumType
      if it = type.index_type
        deps << it
      end
      type.data.each_value { |variant| deps << variant }
      if pt = type.payload_type
        deps << pt
      end
    when Type::EnumVariantType
      deps << type.parent_type
      type.value_types.each { |vt| deps << vt }
      if cvt = type.composite_value_type
        deps << cvt
      end
    when Type::StructType
      type.data.each { |ft| deps << ft }
    when Type::Fn
      type.args.each { |arg| deps << arg }
      deps << type.ret
    end
    deps
  end

  private def collect_type_deps(type : Type, used_set : Set(String), visited : Set(String) = Set(String).new)
    name = type.id_name
    return if visited.includes?(name)

    used_set << name
    visited << name

    deps = direct_type_dependencies(type)
    deps.each do |dep|
      collect_type_deps(dep, used_set, visited)
    end
  end
end
