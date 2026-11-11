class Myc::Backend::GM::BB < Myc::Backend::AbstractBB
  def initialize(@name, @builder, @func, @func_def)
    super
    @temp_counter = 0
    @body_io = IO::Memory.new
    @slots_io = IO::Memory.new
    @slot_counter = 0
  end

  def alloca(name : String, type : Type) : Value
    slot_name = "$#{name}"
    lowir_type = lowir_type(type)
    @slots_io << "  slot #{slot_name} : #{lowir_type}\n"
    wrap_ref(slot_name, type, Value::PP::LocalUninitialized.new(name))
  end

  def vla(type : Type, ptr_type : Type, size : Value) : Value
    elem_size = @builder.layout.size_of(type)
    bytes = new_temp
    emit "#{bytes} = binary mul i64 #{lowir_val(size)}, #{elem_size}"
    temp = new_temp
    emit "#{temp} = stack_alloc #{bytes}"
    wrap_val(temp, ptr_type, Value::PP::Vla.new)
  end

  def load_ref(value : Value) : Value
    if value.type.needs_blit?
      t = new_temp
      emit "#{t} = load #{lowir_type(value)} #{lowir_val(value)}"
      return wrap_val(t, value.type, value.pp)
    end

    lowir_type = lowir_type(value)
    load_op = case type = value.type
              when Type::IntType
                case type.bytes_count
                when 1 then type.signed ? "load i8" : "load u8"
                when 2 then type.signed ? "load typed i16" : "load u16"
                else        "load typed #{lowir_type}"
                end
              when Type::BoolType
                "load i8"
              else
                "load typed #{lowir_type}"
              end

    temp = new_temp
    emit "#{temp} = #{load_op} #{lowir_val(value)}"
    wrap_val(temp, value.type, value.pp)
  end

  def jmp(other : AbstractBB)
    emit "jump ^#{other.name}"
  end

  def indirect_jmp(bb_addr : Value, bbs : Array(AbstractBB))
    idx = lowir_val(bb_addr)
    arms = bbs[0..-2].map { |bb| "#{bb.number}:^#{bb.name}" }.join(", ")
    default = bbs[-1].name
    if arms.empty?
      emit "jump ^#{default}"
    else
      emit "switch #{idx}, ^#{default}, #{arms}"
    end
  end

  def ret(val : Value?)
    if val
      emit "return #{lowir_type(val.type)} #{lowir_val(val)}"
    else
      emit "return void"
    end
  end

  def call(name : String, type_fn : Type::Fn, args : Array(Value)) : Value?
    builder.func_link(name, type_fn)

    ret_type = type_fn.ret
    ret_lowir = lowir_type(ret_type)

    arg_str = String.build do |s|
      args.each_with_index do |arg, index|
        s << ", " if index != 0
        s << lowir_val(arg)
      end
    end

    if ret_type.eq?(func_def.mod.typer.void)
      emit "call void @#{name}(#{arg_str})"
      nil
    else
      t = new_temp
      emit "#{t} = call #{ret_lowir} @#{name}(#{arg_str})"
      wrap_val(t, ret_type, Value::PP::CallResult.new(name))
    end
  end

  def invoke(fn : Value, type_fn : Type::Fn, args : Array(Value)) : Value?
    ret_type = type_fn.ret
    ret_lowir = lowir_type(ret_type)
    fn_val = lowir_val(fn)

    args_str = String.build do |s|
      args.each_with_index do |arg, index|
        s << ", " if index != 0
        s << lowir_val(arg)
      end
    end

    params_str = type_fn.args.map_with_index { |t, i| "%a#{i} : #{lowir_type(t)}" }.join(", ")
    meta = [] of String
    meta << "arity=variadic" if type_fn.vaarg
    sig = "as (#{params_str}) -> #{ret_lowir}"
    sig += " [#{meta.join(", ")}]" unless meta.empty?

    if ret_type.eq?(func_def.mod.typer.void)
      emit "call void #{fn_val}(#{args_str}) #{sig}"
      nil
    else
      t = new_temp
      emit "#{t} = call #{ret_lowir} #{fn_val}(#{args_str}) #{sig}"
      wrap_val(t, ret_type, Value::PP::CallResult.new("invoke"))
    end
  end

  def fn_addr(name : String, type_fn : Type::Fn) : Value
    builder.func_link(name, type_fn)
    val = "@#{name}"
    wrap_val(val, type_fn, Value::PP::FnAddress.new(name))
  end

  def bb_addr(bb : AbstractBB) : Value
    wrap_val(bb.number.to_s, typer.indirect, Value::PP::LabelAddress.new(bb.name))
  end

  def cond(cond : Value, then_bb : AbstractBB, else_bb : AbstractBB)
    emit "branch #{lowir_val(cond)}, ^#{then_bb.name}, ^#{else_bb.name}"
  end

  def select(cond : Value, arg_true : Value, arg_false : Value) : Value
    result_type = lowir_type(arg_true.type)
    t = new_temp
    cond_v = lowir_val(cond)
    true_v = lowir_val(arg_true)
    false_v = lowir_val(arg_false)
    emit "#{t} = select #{result_type} #{cond_v}, #{true_v}, #{false_v}"
    wrap_val(t, arg_true.type, arg_true.pp)
  end

  def store(lhs : Value, rhs : Value)
    if lhs.type.needs_blit?
      size = builder.layout.size_of(lhs.type)
      return if size == 0
      align = builder.layout.alignment_of(lhs.type)

      emit "copyobj #{size}x#{align} #{lowir_val(rhs)}, #{lowir_val(lhs)}"
    else
      lowir_type = lowir_type(lhs.type)
      store_op = case type = lhs.type
                 when Type::IntType
                   case type.bytes_count
                   when 1 then "store i8"
                   when 2 then "store i16"
                   else        "store #{lowir_type}"
                   end
                 when Type::BoolType
                   "store i1"
                 else
                   "store #{lowir_type}"
                 end
      emit "#{store_op} #{lowir_val(rhs)}, #{lowir_val(lhs)}"
    end
  end

  def binary(op : Opcode::Binary::Op, lhs : Value, rhs : Value) : Value?
    l = lowir_val(lhs)
    r = lowir_val(rhs)
    t = new_temp
    ltype = lhs.type
    lowir_type = lowir_type(ltype)

    case op
    when .add?
      emit "#{t} = binary add #{lowir_type} #{l}, #{r}"
      t = wrap_int_result(t, ltype)
    when .sub?
      emit "#{t} = binary sub #{lowir_type} #{l}, #{r}"
      t = wrap_int_result(t, ltype)
    when .mul?
      emit "#{t} = binary mul #{lowir_type} #{l}, #{r}"
      t = wrap_int_result(t, ltype)
    when .div?
      op_name = case ltype
                when Type::IntType
                  ltype.signed ? "div" : "udiv"
                when Type::FloatType
                  "div"
                else
                  return
                end
      emit "#{t} = binary #{op_name} #{lowir_type} #{l}, #{r}"
      t = wrap_int_result(t, ltype)
      return wrap_res(t, ltype, lhs.pp)
    when .rem?
      case ltype
      when Type::IntType
        op_name = ltype.signed ? "mod" : "umod"
        emit "#{t} = binary #{op_name} #{lowir_type} #{l}, #{r}"
        t = wrap_int_result(t, ltype)
        return wrap_res(t, ltype, lhs.pp)
      else
        return
      end
    when .and? then emit "#{t} = binary and #{lowir_type} #{l}, #{r}"
    when .or?  then emit "#{t} = binary or #{lowir_type} #{l}, #{r}"
    when .xor? then emit "#{t} = binary xor #{lowir_type} #{l}, #{r}"
    when .shl?
      emit "#{t} = binary shl #{lowir_type} #{l}, #{r}"
      t = wrap_int_result(t, ltype)
    when .shr?
      op_name = ltype.is_a?(Type::IntType) && !ltype.signed ? "ushr" : "shr"
      emit "#{t} = binary #{op_name} #{lowir_type} #{l}, #{r}"
    when .sar?
      emit "#{t} = binary shr #{lowir_type} #{l}, #{r}"
    when .eq?
      emit "#{t} = cmp eq #{lowir_type} #{l}, #{r}"
      return wrap_res(t, typer.bool, lhs.pp)
    when .not_eq?
      emit "#{t} = cmp ne #{lowir_type} #{l}, #{r}"
      return wrap_res(t, typer.bool, lhs.pp)
    when .less?
      pred = case ltype
             when Type::IntType
               ltype.signed ? "lt" : "ult"
             else
               "lt"
             end
      emit "#{t} = cmp #{pred} #{lowir_type} #{l}, #{r}"
      return wrap_res(t, typer.bool, lhs.pp)
    when .less_eq?
      pred = case ltype
             when Type::IntType
               ltype.signed ? "le" : "ule"
             else
               "le"
             end
      emit "#{t} = cmp #{pred} #{lowir_type} #{l}, #{r}"
      return wrap_res(t, typer.bool, lhs.pp)
    when .more?
      pred = case ltype
             when Type::IntType
               ltype.signed ? "gt" : "ugt"
             else
               "gt"
             end
      emit "#{t} = cmp #{pred} #{lowir_type} #{l}, #{r}"
      return wrap_res(t, typer.bool, lhs.pp)
    when .more_eq?
      pred = case ltype
             when Type::IntType
               ltype.signed ? "ge" : "uge"
             else
               "ge"
             end
      emit "#{t} = cmp #{pred} #{lowir_type} #{l}, #{r}"
      return wrap_res(t, typer.bool, lhs.pp)
    when .min?
      case ltype
      when Type::IntType
        pred = ltype.signed ? "lt" : "ult"
        cmp = new_temp
        emit "#{cmp} = cmp #{pred} #{lowir_type} #{l}, #{r}"
        emit "#{t} = select #{lowir_type} #{cmp}, #{l}, #{r}"
      when Type::FloatType
        func_name = ltype.bytes_count == 8 ? "fmin" : "fminf"
        t = libm_call(func_name, ltype, [lhs, rhs])
      end
      return wrap_res(t, ltype, lhs.pp)
    when .max?
      case ltype
      when Type::IntType
        pred = ltype.signed ? "gt" : "ugt"
        cmp = new_temp
        emit "#{cmp} = cmp #{pred} #{lowir_type} #{l}, #{r}"
        emit "#{t} = select #{lowir_type} #{cmp}, #{l}, #{r}"
      when Type::FloatType
        func_name = ltype.bytes_count == 8 ? "fmax" : "fmaxf"
        t = libm_call(func_name, ltype, [lhs, rhs])
      end
      return wrap_res(t, ltype, lhs.pp)
    when .copysign?
      case ltype
      when Type::FloatType
        func_name = ltype.bytes_count == 8 ? "copysign" : "copysignf"
        t = libm_call(func_name, ltype, [lhs, rhs])
      end
      return wrap_res(t, ltype, lhs.pp)
    when .rotl?
      case ltype
      when Type::IntType
        width = ltype.bytes_count * 8
        shl_temp = new_temp
        shr_temp = new_temp
        sub_temp = new_temp
        emit "#{sub_temp} = binary sub #{lowir_type} #{width}, #{r}"
        emit "#{shl_temp} = binary shl #{lowir_type} #{l}, #{r}"
        emit "#{shr_temp} = binary shr #{lowir_type} #{l}, #{sub_temp}"
        emit "#{t} = binary or #{lowir_type} #{shl_temp}, #{shr_temp}"
        t = wrap_int_result(t, ltype)
      end
      return wrap_res(t, ltype, lhs.pp)
    when .rotr?
      case ltype
      when Type::IntType
        width = ltype.bytes_count * 8
        shr_temp = new_temp
        shl_temp = new_temp
        sub_temp = new_temp
        emit "#{sub_temp} = binary sub #{lowir_type} #{width}, #{r}"
        emit "#{shr_temp} = binary shr #{lowir_type} #{l}, #{r}"
        emit "#{shl_temp} = binary shl #{lowir_type} #{l}, #{sub_temp}"
        emit "#{t} = binary or #{lowir_type} #{shl_temp}, #{shr_temp}"
        t = wrap_int_result(t, ltype)
      end
      return wrap_res(t, ltype, lhs.pp)
    else
      return nil
    end

    wrap_res(t, ltype, lhs.pp)
  end

  def unary(op : Opcode::Unary::Op, rhs : Value) : Value?
    val = lowir_val(rhs)
    type = rhs.type
    lowir_type = lowir_type(type)
    t = new_temp

    case op
    when .lnot?
      case type
      when Type::IntType, Type::BoolType
        emit "#{t} = cmp eq #{lowir_type} #{val}, 0"
      end
    when .bnot?
      case type
      when Type::IntType
        emit "#{t} = unary bitnot #{lowir_type} #{val}"
        t = wrap_int_result(t, type)
      end
    when .neg?
      emit "#{t} = unary neg #{lowir_type} #{val}"
      t = wrap_int_result(t, type) if type.is_a?(Type::IntType)
    when .sqrt?
      case type
      when Type::FloatType
        emit "#{t} = unary sqrt #{lowir_type} #{val}"
      end
    when .ceil?
      case type
      when Type::FloatType
        func_name = type.bytes_count == 8 ? "ceil" : "ceilf"
        t = libm_call(func_name, type, [rhs])
      end
    when .floor?
      case type
      when Type::FloatType
        func_name = type.bytes_count == 8 ? "floor" : "floorf"
        t = libm_call(func_name, type, [rhs])
      end
    when .trunc?
      case type
      when Type::FloatType
        func_name = type.bytes_count == 8 ? "trunc" : "truncf"
        t = libm_call(func_name, type, [rhs])
      end
    when .nearest?
      case type
      when Type::FloatType
        func_name = type.bytes_count == 8 ? "nearbyint" : "nearbyintf"
        t = libm_call(func_name, type, [rhs])
      end
    when .abs?
      case type
      when Type::IntType
        cmp = new_temp
        neg = new_temp
        emit "#{cmp} = cmp lt #{lowir_type} #{val}, 0"
        emit "#{neg} = unary neg #{lowir_type} #{val}"
        emit "#{t} = select #{lowir_type} #{cmp}, #{neg}, #{val}"
        t = wrap_int_result(t, type)
      when Type::FloatType
        func_name = type.bytes_count == 8 ? "fabs" : "fabsf"
        t = libm_call(func_name, type, [rhs])
      end
    when .clz?
      case type
      when Type::IntType
        width = type.bytes_count * 8

        if width == 64
          cmp = new_temp
          emit "#{cmp} = cmp eq i64 #{val}, 0"
          clz_t = new_temp
          emit "#{clz_t} = unary clz i64 #{val}"
          emit "#{t} = select i64 #{cmp}, 64, #{clz_t}"
        elsif width == 32
          cmp = new_temp
          emit "#{cmp} = cmp eq i32 #{val}, 0"
          clz_t = new_temp
          emit "#{clz_t} = unary clz i32 #{val}"
          emit "#{t} = select i32 #{cmp}, 32, #{clz_t}"
        else
          ext = type.signed ? "sext" : "zext"
          ext_val = new_temp
          emit "#{ext_val} = convert #{ext} u32 #{lowir_type} #{val}"
          cmp = new_temp
          emit "#{cmp} = cmp eq u32 #{ext_val}, 0"
          clz_t = new_temp
          emit "#{clz_t} = unary clz u32 #{ext_val}"
          sub_t = new_temp
          emit "#{sub_t} = binary sub u32 #{clz_t}, #{32 - width}"
          emit "#{t} = select i32 #{cmp}, #{width}, #{sub_t}"
        end
        t = wrap_int_result(t, type)
      end
    when .ctz?
      case type
      when Type::IntType
        width = type.bytes_count * 8

        if width == 64
          cmp = new_temp
          emit "#{cmp} = cmp eq i64 #{val}, 0"
          ctz_t = new_temp
          emit "#{ctz_t} = unary ctz i64 #{val}"
          emit "#{t} = select i64 #{cmp}, 64, #{ctz_t}"
        elsif width == 32
          cmp = new_temp
          emit "#{cmp} = cmp eq i32 #{val}, 0"
          ctz_t = new_temp
          emit "#{ctz_t} = unary ctz i32 #{val}"
          emit "#{t} = select i32 #{cmp}, 32, #{ctz_t}"
        else
          ext = type.signed ? "sext" : "zext"
          ext_val = new_temp
          emit "#{ext_val} = convert #{ext} u32 #{lowir_type} #{val}"
          cmp = new_temp
          emit "#{cmp} = cmp eq u32 #{ext_val}, 0"
          ctz_t = new_temp
          emit "#{ctz_t} = unary ctz u32 #{ext_val}"
          emit "#{t} = select i32 #{cmp}, #{width}, #{ctz_t}"
        end
        t = wrap_int_result(t, type)
      end
    when .popcnt?
      case type
      when Type::IntType
        width = type.bytes_count * 8
        if width == 64
          emit "#{t} = unary popcount i64 #{val}"
        elsif width == 32
          emit "#{t} = unary popcount #{type.signed ? "i32" : "u32"} #{val}"
        else
          ext = type.signed ? "sext" : "zext"
          ext_val = new_temp
          emit "#{ext_val} = convert #{ext} u32 #{lowir_type} #{val}"
          emit "#{t} = unary popcount u32 #{ext_val}"
        end
        t = wrap_int_result(t, type)
      end
    else
      return nil
    end

    wrap_res(t, type, rhs.pp)
  end

  private def libm_call(name : String, ret_type : Type, args : Array(Value)) : String
    arg_types = args.map { |a| a.type }
    type_fn = Type::Fn.new(Location.new("", 0), arg_types, ret_type)
    builder.func_link(name, type_fn)
    t = new_temp
    arg_str = args.map { |a| lowir_val(a) }.join(", ")
    emit "#{t} = call #{lowir_type(ret_type)} @#{name}(#{arg_str})"
    t
  end

  def switch(index : Value, case_values : Array(Value), case_bbs : Array(AbstractBB), default_bb : AbstractBB)
    idx = lowir_val(index)
    arms = case_values.each_with_index.map { |val, i| "#{lowir_val(val)}:^#{case_bbs[i].name}" }.join(", ")
    emit "switch #{idx}, ^#{default_bb.name}, #{arms}"
  end

  def cast?(value : Value, from_type : Type, to_type : Type) : Value?
    from_lowir = lowir_type(from_type)
    to_lowir = lowir_type(to_type)
    val = lowir_val(value)
    t = new_temp

    case {from_type, to_type}
    when {Type::IntType, Type::IntType}
      from_size = from_type.bytes_count
      to_size = to_type.bytes_count
      if to_size == from_size
        wrap_res(val, to_type, value.pp)
      elsif to_size > from_size
        op = from_type.signed ? "sext" : "zext"
        emit "#{t} = convert #{op} #{to_lowir} #{from_lowir} #{val}"
        wrap_res(t, to_type, value.pp)
      else
        emit "#{t} = convert trunc #{to_lowir} #{from_lowir} #{val}"
        wrap_res(t, to_type, value.pp)
      end
    when {Type::IntType, Type::FloatType}
      op = from_type.signed ? "sitofp" : "uitofp"
      emit "#{t} = convert #{op} #{to_lowir} #{from_lowir} #{val}"
      wrap_res(t, to_type, value.pp)
    when {Type::FloatType, Type::IntType}
      op = to_type.signed ? "fptosi" : "fptoui"
      emit "#{t} = convert #{op} #{to_lowir} #{from_lowir} #{val}"
      wrap_res(t, to_type, value.pp)
    when {Type::FloatType, Type::FloatType}
      if to_type.bytes_count > from_type.bytes_count
        emit "#{t} = convert fpext #{to_lowir} #{from_lowir} #{val}"
      else
        emit "#{t} = convert fptrunc #{to_lowir} #{from_lowir} #{val}"
      end
      wrap_res(t, to_type, value.pp)
    when {Type::BoolType, Type::IntType}
      emit "#{t} = convert zext #{to_lowir} i1 #{val}"
      wrap_res(t, to_type, value.pp)
    when {Type::PtrType, Type::PtrType}
      wrap_res(val, to_type, value.pp)
    when {Type::IntType, Type::PtrType}
      emit "#{t} = copy ptr #{val}"
      wrap_res(t, to_type, value.pp)
    when {Type::PtrType, Type::IntType}
      emit "#{t} = copy #{to_lowir} #{val}"
      wrap_res(t, to_type, value.pp)
    when {Type::IntType, Type::Fn}
      emit "#{t} = copy ptr #{val}"
      wrap_res(t, to_type, value.pp)
    when {Type::Fn, Type::IntType}
      if to_type.bytes_count >= builder.layout.target.pointer_size
        emit "#{t} = copy #{to_lowir} #{val}"
        wrap_res(t, to_type, value.pp)
      end
    when {Type::PtrType, Type::Fn}
      wrap_res(val, to_type, value.pp)
    when {Type::Fn, Type::PtrType}
      wrap_res(val, to_type, value.pp)
    end
  end

  def to?(value : Value, from_type : Type, to_type : Type) : Value?
    from_lowir = lowir_type(from_type)
    to_lowir = lowir_type(to_type)
    val = lowir_val(value)
    t = new_temp

    case {from_type, to_type}
    when {Type::IntType, Type::IntType}
      from_size = from_type.bytes_count
      to_size = to_type.bytes_count
      if to_size > from_size
        op = from_type.signed ? "sext" : "zext"
        emit "#{t} = convert #{op} #{to_lowir} #{from_lowir} #{val}"
        wrap_res(t, to_type, value.pp)
      elsif to_size == from_size && from_type.signed == to_type.signed
        wrap_res(val, to_type, value.pp)
      end
    when {Type::IntType, Type::FloatType}
      if to_type.bytes_count >= from_type.bytes_count
        op = from_type.signed ? "sitofp" : "uitofp"
        emit "#{t} = convert #{op} #{to_lowir} #{from_lowir} #{val}"
        wrap_res(t, to_type, value.pp)
      end
    when {Type::FloatType, Type::FloatType}
      if to_type.bytes_count > from_type.bytes_count
        emit "#{t} = convert fpext #{to_lowir} #{from_lowir} #{val}"
        wrap_res(t, to_type, value.pp)
      elsif to_type.bytes_count == from_type.bytes_count
        wrap_res(val, to_type, value.pp)
      end
    when {Type::PtrType, Type::PtrType}
      if to_type.target_type.is_a?(Type::VoidType)
        wrap_res(val, to_type, value.pp)
      end
    when {Type::IndirectType, Type::PtrType}
      wrap_res(val, to_type, value.pp)
    when {Type::PtrType, Type::IndirectType}
      wrap_res(val, to_type, value.pp)
    end
  end

  def field(value : Value, field_type : Type, offset : Int32) : Value
    byte_offset = builder.layout.field_offset(value.type, offset.to_u64)
    if byte_offset == 0
      wrap_ref(lowir_val(value), field_type, value.pp)
    else
      base = addr_or_val(value)
      field_ptr = new_temp
      emit "#{field_ptr} = index i8 #{base}, #{byte_offset}"
      wrap_ref(field_ptr, field_type, value.pp)
    end
  end

  def extract_value(value : Value, field_type : Type, offset : Int32) : Value
    field(value, field_type, offset)
  end

  def deref(value : Value, target_type : Type) : Value
    wrap_ref(lowir_val(value), target_type, value.pp)
  end

  def addr(value : Value, ptr_type : Type) : Value
    wrap_val(addr_or_val(value), ptr_type, value.pp)
  end

  def offset(value : Value, target_type : Type, offset : Value) : Value
    ptr_val = lowir_val(value)
    idx = lowir_val(offset)
    idx_val = case index_type = offset.type
              when Type::IntType
                if index_type.bytes_count < 8
                  extension = index_type.signed ? "sext" : "zext"
                  new_temp.tap { |l| emit "#{l} = convert #{extension} i64 #{lowir_type(index_type)} #{idx}" }
                elsif index_type.bytes_count > 8
                  new_temp.tap { |l| emit "#{l} = convert trunc i64 #{lowir_type(index_type)} #{idx}" }
                else
                  idx
                end
              else
                idx
              end
    t = new_temp
    emit "#{t} = index #{lowir_type(target_type)} #{ptr_val}, #{idx_val}"
    wrap_val(t, value.type, value.pp)
  end

  def bitcast(value : Value, to_type : Type) : Value
    wrap_ref(lowir_val(value), to_type, value.pp)
  end

  def va_start(arg : Value, val : Value)
    emit "va_start #{addr_or_val(arg)}"
  end

  def va_end(arg : Value)
  end

  def va_arg(arg : Value, type : Type) : Value
    t = new_temp
    emit "#{t} = va_arg #{lowir_type(type)} #{addr_or_val(arg)}"
    wrap_res(t, type, arg.pp)
  end

  def builder
    @builder.as(Builder)
  end

  def emit(str : String)
    @body_io << "    " << str << '\n'
  end

  def copy_slots(to : IO)
    @slots_io.rewind
    IO.copy(@slots_io, to)
  end

  def copy_data(to : IO, _emit_label : Bool)
    emit_label(@name, to) if _emit_label
    builder.copy_io(@body_io, to)
  end

  private def emit_label(name : String, io = @body_io)
    io << "  block ^"
    io << name
    io << ":\n"
  end

  private def lowir_type(v : Value) : String
    lowir_type(v.type)
  end

  private def lowir_type(t : Type) : String
    builder.lowir_type(t)
  end

  def func
    @func.as(Func)
  end

  def new_temp : String
    func.new_temp
  end

  private def wrap_val(val : String, type : Type, pp : Value::PP) : Value
    Value.new(BBVal.new(val), type, Value::MM::Val, pp)
  end

  private def wrap_ref(val : String, type : Type, pp : Value::PP) : Value
    Value.new(BBVal.new(val), type, Value::MM::Ref, pp)
  end

  private def wrap_res(val : String, type : Type, pp : Value::PP) : Value
    wrap_val(val, type, pp)
  end

  private def typer : Typer
    @func_def.mod.typer
  end

  private def wrap_int_result(t : String, type : Type) : String
    t
  end

  def _lowir_val(v : Value) : String
    v.bbval.as(BBVal).val
  end

  def lowir_val(arg : Value) : String
    val = _lowir_val(arg)
    if val.starts_with?("addr ")
      t = new_temp
      emit "#{t} = #{val}"
      t
    else
      val
    end
  end

  private def addr_or_val(value : Value) : String
    val = _lowir_val(value)
    if val.starts_with?("$") || val.starts_with?("@")
      t = new_temp
      emit "#{t} = addr #{val}"
      t
    else
      val
    end
  end
end
