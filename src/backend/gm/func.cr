class Myc::Backend::GM::Func < Myc::Backend::AbstractFunc
  getter temp_counter : Int32
  getter body_io : IO::Memory

  def initialize(@builder : Builder, @func_def : Mod::FuncDef, @header_mod : Mod)
    super(@builder, @func_def, @header_mod)
    @temp_counter = 0
    @body_io = IO::Memory.new
  end

  def bb_class : AbstractBB.class
    BB
  end

  def visitor_class : AbstractVisitor.class
    Visitor
  end

  def builder
    @builder.as(Builder)
  end

  def params : Array(Value)
    @func_def.type_fn.args.map_with_index do |type, index|
      if type.needs_blit?
        param_name = "__myc_blit_arg_#{index}"
        slot_ref = alloca_bb.as(BB).alloca(param_name, type)
        slot_ref.pp = Value::PP::Local.new(param_name)

        size = builder.layout.size_of(type)
        align = builder.layout.alignment_of(type)
        home_ptr = alloca_bb.as(BB).new_temp
        alloca_bb.as(BB).emit "#{home_ptr} = addr #{alloca_bb.as(BB).lowir_val(slot_ref)}"
        alloca_bb.as(BB).emit "copyobj #{size}x#{align} %arg#{index}, #{home_ptr}"
        slot_ref
      else
        Value.new(BBVal.new("%arg#{index}"), type, Value::MM::Val, Value::PP::Param.new(index))
      end
    end
  end

  def emit(s : String)
    @body_io << s
  end

  def build
    type_fn = @func_def.type_fn

    meta = [] of String
    @func_def.attrs.each do |attr|
      case attr
      when Mod::FuncDef::Attr::Private
        meta << "binding=internal"
      end
    end
    meta << "role=entry" if @func_def.name == "main"
    meta << "arity=variadic" if type_fn.vaarg

    ret_type = builder.lowir_type(type_fn.ret)
    args = type_fn.args.map_with_index do |t, i|
      "%arg#{i} : #{builder.lowir_type(t)}"
    end

    emit "function @#{@func_def.name}("
    emit args.join(", ")
    emit ") -> "
    emit ret_type
    unless meta.empty?
      emit " ["
      emit meta.join(", ")
      emit "]"
    end
    emit " {\n"

    v = new_visitor
    v.visit

    alloca_bb.as(BB).copy_slots(body_io)
    emit "  block ^alloca:\n"
    alloca_bb.as(BB).copy_data(body_io, false)
    emit "    jump ^body\n"

    v.bb.as(BB).emit "jump ^ret"

    emit "  block ^body:\n"
    body_bb.as(BB).copy_data(body_io, false)

    @bbs.each do |name, bb|
      next if name == "alloca" || name == "body" || name == "ret" || name == "__myc_dummy_bb__"
      bb.as(BB).copy_data(body_io, true)
    end

    emit "  block ^ret:\n"
    if @func_def.have_ret?
      if (r = result) && r.type.needs_blit?
        emit "    %ret_val = copy #{builder.lowir_type(type_fn.ret)} $__myc_result\n"
        emit "    return #{builder.lowir_type(type_fn.ret)} %ret_val\n"
      else
        ret_type = type_fn.ret
        lowir_ret_type = builder.lowir_type(ret_type)

        if ret_type.is_a?(Type::IntType) && ret_type.bytes_count < 4
          load_op = case ret_type.bytes_count
                    when 1 then ret_type.signed ? "load i8" : "load u8"
                    when 2 then ret_type.signed ? "load typed i16" : "load u16"
                    else        "load #{lowir_ret_type}"
                    end
          emit "    %ret_val = #{load_op} $__myc_result\n"
        elsif ret_type.is_a?(Type::BoolType)
          emit "    %ret_val = load u8 $__myc_result\n"
        else
          emit "    %ret_val = load typed #{lowir_ret_type} $__myc_result\n"
        end

        emit "    return #{lowir_ret_type} %ret_val\n"
      end
    else
      emit "    return void\n"
    end

    emit "}\n\n"
  end

  def new_temp : String
    @temp_counter += 1
    "%t#{@temp_counter}"
  end
end
