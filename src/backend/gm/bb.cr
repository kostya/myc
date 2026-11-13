class Myc::Backend::GM::BB < Myc::Backend::AbstractBB
  getter id : UInt32
  @terminated = false

  def initialize(@name, @builder, @func, @func_def)
    super
    @id = @name == "__myc_dummy_bb__" ? NO_ID : @func.as(Func).next_block
  end

  def alloca(name : String, type : Type) : Value
    slot = func.slot(lowir_type(type))
    wrap_ref(slot, type, Value::PP::LocalUninitialized.new(name))
  end

  def vla(type : Type, ptr_type : Type, size : Value) : Value
    elem_size = @builder.layout.size_of(type)
    bytes = none
    bytes = emit_value(IROp::Binary, GM.ir_type(IRType::I64), lowir_val(size), elem_size, sub: IRBinary::Mul.value)
    temp = none
    temp = emit_value(IROp::StackAlloc, GM.ir_type(IRType::Ptr), bytes)
    wrap_val(temp, ptr_type, Value::PP::Vla.new)
  end

  def load_ref(value : Value) : Value
    type = lowir_type(value)
    flags = value.type.needs_blit? ? 0_u8 : 64_u8
    if value.type.is_a?(Type::BoolType)
      type = GM.ir_type(IRType::I8)
      flags = 0_u8
    elsif (integer = value.type).is_a?(Type::IntType) && (integer.bytes_count == 1 || (integer.bytes_count == 2 && !integer.signed))
      flags = 0_u8
    end
    temp = none
    temp = emit_value(IROp::Load, type, lowir_val(value), flags: flags)
    wrap_val(temp, value.type, value.pp)
  end

  def jmp(other : AbstractBB)
    emit(none, IROp::Jump, a: block_value(other))
  end

  def indirect_jmp(bb_addr : Value, bbs : Array(AbstractBB))
    return jmp(bbs[-1]) if bbs.size == 1
    first = func.operand_count
    bbs.each_with_index do |bb, i|
      break if i == bbs.size - 1
      func.append_operand(func.integer(bb.number))
      func.append_operand(block_value(bb))
    end
    emit(none, IROp::Switch, a: lowir_val(bb_addr), b: block_value(bbs[-1]),
      extra_first: first, extra_count: ((bbs.size - 1) * 2).to_u32)
  end

  def unreachable
    emit(none, IROp::Unreachable)
  end

  def ret(val : Value?)
    if val
      emit(none, IROp::Return, lowir_type(val.type), lowir_val(val))
    else
      emit(none, IROp::Return)
    end
  end

  def call(name : String, type_fn : Type::Fn, args : Array(Value)) : Value?
    builder.func_link(name, type_fn)
    call_value(GM.ir_value(IRKind::Symbol, builder.symbol(name)), type_fn, args, name)
  end

  def invoke(fn : Value, type_fn : Type::Fn, args : Array(Value)) : Value?
    call_value(lowir_val(fn), type_fn, args, "invoke", builder.signature(type_fn))
  end

  private def call_value(callee : LibGM::Value, type_fn : Type::Fn, args : Array(Value), name : String, signature = NO_ID) : Value?
    first = func.operand_count
    args.each { |arg| func.append_operand(lowir_val(arg)) }
    ret_type = type_fn.ret
    flags = signature == NO_ID ? 0_u8 : 2_u8
    if ret_type.eq?(typer.void)
      emit(none, IROp::Call, lowir_type(ret_type), callee, extra_first: first, extra_count: args.size.to_u32,
        flags: flags, immediate: signature.to_i64)
      nil
    else
      result = emit_value(IROp::Call, lowir_type(ret_type), callee, extra_first: first, extra_count: args.size.to_u32,
        flags: flags, immediate: signature.to_i64)
      wrap_val(result, ret_type, Value::PP::CallResult.new(name))
    end
  end

  def fn_addr(name : String, type_fn : Type::Fn) : Value
    builder.func_link(name, type_fn)
    val = GM.ir_value(IRKind::Symbol, builder.symbol(name))
    wrap_val(val, type_fn, Value::PP::FnAddress.new(name))
  end

  def bb_addr(bb : AbstractBB) : Value
    wrap_val(func.integer(bb.number), typer.indirect, Value::PP::LabelAddress.new(bb.name))
  end

  def cond(cond : Value, then_bb : AbstractBB, else_bb : AbstractBB)
    emit(none, IROp::Branch, a: lowir_val(cond), b: block_value(then_bb), c: block_value(else_bb))
  end

  def select(cond : Value, arg_true : Value, arg_false : Value) : Value
    result_type = lowir_type(arg_true.type)
    t = none
    cond_v = lowir_val(cond)
    true_v = lowir_val(arg_true)
    false_v = lowir_val(arg_false)
    t = emit_value(IROp::Select, result_type, cond_v, true_v, false_v)
    wrap_val(t, arg_true.type, arg_true.pp)
  end

  def store(lhs : Value, rhs : Value)
    if lhs.type.needs_blit?
      size = builder.layout.size_of(lhs.type)
      return if size == 0
      copy_object(lowir_val(rhs), lowir_val(lhs), size, builder.layout.alignment_of(lhs.type))
    else
      type = lowir_type(lhs.type)
      # Preserve the text producer's signed byte/halfword storage view.
      type = GM.ir_type(IRType::I8) if type == GM.ir_type(IRType::U8)
      type = GM.ir_type(IRType::I16) if type == GM.ir_type(IRType::U16)
      emit(none, IROp::Store, type, lowir_val(rhs), lowir_val(lhs))
    end
  end

  def binary(op : Opcode::Binary::Op, lhs : Value, rhs : Value) : Value?
    l = lowir_val(lhs)
    r = lowir_val(rhs)
    t = none
    ltype = lhs.type
    lowir_type = lowir_type(ltype)

    case op
    when .add?
      t = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Add.value)
    when .sub?
      t = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Sub.value)
    when .mul?
      t = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Mul.value)
    when .div?
      op_name = case ltype
                when Type::IntType
                  ltype.signed ? IRBinary::Div : IRBinary::UDiv
                when Type::FloatType
                  IRBinary::Div
                else
                  return
                end
      t = emit_value(IROp::Binary, lowir_type, l, r, sub: op_name.value)

      return wrap_res(t, ltype, lhs.pp)
    when .rem?
      case ltype
      when Type::IntType
        op_name = ltype.signed ? IRBinary::Mod : IRBinary::UMod
        t = emit_value(IROp::Binary, lowir_type, l, r, sub: op_name.value)

        return wrap_res(t, ltype, lhs.pp)
      else
        return
      end
    when .and? then t = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::And.value)
    when .or?  then t = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Or.value)
    when .xor? then t = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Xor.value)
    when .shl?
      t = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Shl.value)
    when .shr?
      op_name = ltype.is_a?(Type::IntType) && !ltype.signed ? IRBinary::UShr : IRBinary::Shr
      t = emit_value(IROp::Binary, lowir_type, l, r, sub: op_name.value)
    when .sar?
      t = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Shr.value)
    when .eq?
      t = emit_value(IROp::Compare, lowir_type, l, r, sub: IRCmp::Eq.value)
      return wrap_res(t, typer.bool, lhs.pp)
    when .not_eq?
      t = emit_value(IROp::Compare, lowir_type, l, r, sub: IRCmp::Ne.value)
      return wrap_res(t, typer.bool, lhs.pp)
    when .less?
      pred = case ltype
             when Type::IntType
               ltype.signed ? IRCmp::Lt : IRCmp::Ult
             else
               IRCmp::Lt
             end
      t = emit_value(IROp::Compare, lowir_type, l, r, sub: pred.value)
      return wrap_res(t, typer.bool, lhs.pp)
    when .less_eq?
      pred = case ltype
             when Type::IntType
               ltype.signed ? IRCmp::Le : IRCmp::Ule
             else
               IRCmp::Le
             end
      t = emit_value(IROp::Compare, lowir_type, l, r, sub: pred.value)
      return wrap_res(t, typer.bool, lhs.pp)
    when .more?
      pred = case ltype
             when Type::IntType
               ltype.signed ? IRCmp::Gt : IRCmp::Ugt
             else
               IRCmp::Gt
             end
      t = emit_value(IROp::Compare, lowir_type, l, r, sub: pred.value)
      return wrap_res(t, typer.bool, lhs.pp)
    when .more_eq?
      pred = case ltype
             when Type::IntType
               ltype.signed ? IRCmp::Ge : IRCmp::Uge
             else
               IRCmp::Ge
             end
      t = emit_value(IROp::Compare, lowir_type, l, r, sub: pred.value)
      return wrap_res(t, typer.bool, lhs.pp)
    when .min?
      case ltype
      when Type::IntType
        pred = ltype.signed ? IRCmp::Lt : IRCmp::Ult
        cmp = none
        cmp = emit_value(IROp::Compare, lowir_type, l, r, sub: pred.value)
        t = emit_value(IROp::Select, lowir_type, cmp, l, r)
      when Type::FloatType
        func_name = ltype.bytes_count == 8 ? "fmin" : "fminf"
        t = libm_call(func_name, ltype, [lhs, rhs])
      end
      return wrap_res(t, ltype, lhs.pp)
    when .max?
      case ltype
      when Type::IntType
        pred = ltype.signed ? IRCmp::Gt : IRCmp::Ugt
        cmp = none
        cmp = emit_value(IROp::Compare, lowir_type, l, r, sub: pred.value)
        t = emit_value(IROp::Select, lowir_type, cmp, l, r)
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
        shl_temp = none
        shr_temp = none
        sub_temp = none
        sub_temp = emit_value(IROp::Binary, lowir_type, width, r, sub: IRBinary::Sub.value)
        shl_temp = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Shl.value)
        shr_temp = emit_value(IROp::Binary, lowir_type, l, sub_temp, sub: IRBinary::Shr.value)
        t = emit_value(IROp::Binary, lowir_type, shl_temp, shr_temp, sub: IRBinary::Or.value)
      end
      return wrap_res(t, ltype, lhs.pp)
    when .rotr?
      case ltype
      when Type::IntType
        width = ltype.bytes_count * 8
        shr_temp = none
        shl_temp = none
        sub_temp = none
        sub_temp = emit_value(IROp::Binary, lowir_type, width, r, sub: IRBinary::Sub.value)
        shr_temp = emit_value(IROp::Binary, lowir_type, l, r, sub: IRBinary::Shr.value)
        shl_temp = emit_value(IROp::Binary, lowir_type, l, sub_temp, sub: IRBinary::Shl.value)
        t = emit_value(IROp::Binary, lowir_type, shl_temp, shr_temp, sub: IRBinary::Or.value)
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
    t = none

    case op
    when .lnot?
      case type
      when Type::IntType, Type::BoolType
        t = emit_value(IROp::Compare, lowir_type, val, func.integer(0), sub: IRCmp::Eq.value)
      end
    when .bnot?
      case type
      when Type::IntType
        t = emit_value(IROp::Unary, lowir_type, val, sub: IRUnary::BitNot.value)
      end
    when .neg?
      t = emit_value(IROp::Unary, lowir_type, val, sub: IRUnary::Neg.value)
    when .sqrt?
      case type
      when Type::FloatType
        t = emit_value(IROp::Unary, lowir_type, val, sub: IRUnary::Sqrt.value)
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
        cmp = none
        neg = none
        cmp = emit_value(IROp::Compare, lowir_type, val, func.integer(0), sub: IRCmp::Lt.value)
        neg = emit_value(IROp::Unary, lowir_type, val, sub: IRUnary::Neg.value)
        t = emit_value(IROp::Select, lowir_type, cmp, neg, val)
      when Type::FloatType
        func_name = type.bytes_count == 8 ? "fabs" : "fabsf"
        t = libm_call(func_name, type, [rhs])
      end
    when .clz?
      case type
      when Type::IntType
        width = type.bytes_count * 8

        if width == 64
          cmp = none
          cmp = emit_value(IROp::Compare, GM.ir_type(IRType::I64), val, func.integer(0), sub: IRCmp::Eq.value)
          clz_t = none
          clz_t = emit_value(IROp::Unary, GM.ir_type(IRType::I64), val, sub: IRUnary::CountLeadingZeros.value)
          t = emit_value(IROp::Select, GM.ir_type(IRType::I64), cmp, func.integer(64), clz_t)
        elsif width == 32
          cmp = none
          cmp = emit_value(IROp::Compare, GM.ir_type(IRType::I32), val, func.integer(0), sub: IRCmp::Eq.value)
          clz_t = none
          clz_t = emit_value(IROp::Unary, GM.ir_type(IRType::I32), val, sub: IRUnary::CountLeadingZeros.value)
          t = emit_value(IROp::Select, GM.ir_type(IRType::I32), cmp, func.integer(32), clz_t)
        else
          ext = type.signed ? IRConvert::SExt : IRConvert::ZExt
          ext_val = none
          ext_val = emit_value(IROp::Convert, GM.ir_type(IRType::U32), val, sub: ext.value, immediate: lowir_type.to_i64!)
          cmp = none
          cmp = emit_value(IROp::Compare, GM.ir_type(IRType::U32), ext_val, func.integer(0), sub: IRCmp::Eq.value)
          clz_t = none
          clz_t = emit_value(IROp::Unary, GM.ir_type(IRType::U32), ext_val, sub: IRUnary::CountLeadingZeros.value)
          sub_t = none
          sub_t = emit_value(IROp::Binary, GM.ir_type(IRType::U32), clz_t, 32 - width, sub: IRBinary::Sub.value)
          t = emit_value(IROp::Select, GM.ir_type(IRType::I32), cmp, width, sub_t)
        end
      end
    when .ctz?
      case type
      when Type::IntType
        width = type.bytes_count * 8

        if width == 64
          cmp = none
          cmp = emit_value(IROp::Compare, GM.ir_type(IRType::I64), val, func.integer(0), sub: IRCmp::Eq.value)
          ctz_t = none
          ctz_t = emit_value(IROp::Unary, GM.ir_type(IRType::I64), val, sub: IRUnary::CountTrailingZeros.value)
          t = emit_value(IROp::Select, GM.ir_type(IRType::I64), cmp, func.integer(64), ctz_t)
        elsif width == 32
          cmp = none
          cmp = emit_value(IROp::Compare, GM.ir_type(IRType::I32), val, func.integer(0), sub: IRCmp::Eq.value)
          ctz_t = none
          ctz_t = emit_value(IROp::Unary, GM.ir_type(IRType::I32), val, sub: IRUnary::CountTrailingZeros.value)
          t = emit_value(IROp::Select, GM.ir_type(IRType::I32), cmp, func.integer(32), ctz_t)
        else
          ext = type.signed ? IRConvert::SExt : IRConvert::ZExt
          ext_val = none
          ext_val = emit_value(IROp::Convert, GM.ir_type(IRType::U32), val, sub: ext.value, immediate: lowir_type.to_i64!)
          cmp = none
          cmp = emit_value(IROp::Compare, GM.ir_type(IRType::U32), ext_val, func.integer(0), sub: IRCmp::Eq.value)
          ctz_t = none
          ctz_t = emit_value(IROp::Unary, GM.ir_type(IRType::U32), ext_val, sub: IRUnary::CountTrailingZeros.value)
          t = emit_value(IROp::Select, GM.ir_type(IRType::I32), cmp, width, ctz_t)
        end
      end
    when .popcnt?
      case type
      when Type::IntType
        width = type.bytes_count * 8
        if width == 64
          t = emit_value(IROp::Unary, GM.ir_type(IRType::I64), val, sub: IRUnary::CountOnes.value)
        elsif width == 32
          t = emit_value(IROp::Unary, type.signed ? GM.ir_type(IRType::I32) : GM.ir_type(IRType::U32), val, sub: IRUnary::CountOnes.value)
        else
          ext = type.signed ? IRConvert::SExt : IRConvert::ZExt
          ext_val = none
          ext_val = emit_value(IROp::Convert, GM.ir_type(IRType::U32), val, sub: ext.value, immediate: lowir_type.to_i64!)
          t = emit_value(IROp::Unary, GM.ir_type(IRType::U32), ext_val, sub: IRUnary::CountOnes.value)
        end
      end
    else
      return nil
    end

    wrap_res(t, type, rhs.pp)
  end

  def switch(index : Value, case_values : Array(Value), case_bbs : Array(AbstractBB), default_bb : AbstractBB)
    first = func.operand_count
    case_values.each_with_index do |value, i|
      func.append_operand(lowir_val(value))
      func.append_operand(block_value(case_bbs[i]))
    end
    emit(none, IROp::Switch, a: lowir_val(index), b: block_value(default_bb),
      extra_first: first, extra_count: (case_values.size * 2).to_u32)
  end

  def cast?(value : Value, from_type : Type, to_type : Type) : Value?
    from_lowir = lowir_type(from_type)
    to_lowir = lowir_type(to_type)
    val = lowir_val(value)
    t = none

    case {from_type, to_type}
    when {Type::IntType, Type::IntType}
      from_size = from_type.bytes_count
      to_size = to_type.bytes_count
      if to_size == from_size
        wrap_res(val, to_type, value.pp)
      elsif to_size > from_size
        op = from_type.signed ? IRConvert::SExt : IRConvert::ZExt
        t = emit_value(IROp::Convert, to_lowir, val, sub: op.value, immediate: from_lowir.to_i64!)
        wrap_res(t, to_type, value.pp)
      else
        t = emit_value(IROp::Convert, to_lowir, val, sub: IRConvert::Trunc.value, immediate: from_lowir.to_i64!)
        wrap_res(t, to_type, value.pp)
      end
    when {Type::IntType, Type::FloatType}
      op = from_type.signed ? IRConvert::SIToFP : IRConvert::UIToFP
      t = emit_value(IROp::Convert, to_lowir, val, sub: op.value, immediate: from_lowir.to_i64!)
      wrap_res(t, to_type, value.pp)
    when {Type::FloatType, Type::IntType}
      op = to_type.signed ? IRConvert::FPToSI : IRConvert::FPToUI
      t = emit_value(IROp::Convert, to_lowir, val, sub: op.value, immediate: from_lowir.to_i64!)
      wrap_res(t, to_type, value.pp)
    when {Type::FloatType, Type::FloatType}
      if to_type.bytes_count > from_type.bytes_count
        t = emit_value(IROp::Convert, to_lowir, val, sub: IRConvert::FPExt.value, immediate: from_lowir.to_i64!)
      else
        t = emit_value(IROp::Convert, to_lowir, val, sub: IRConvert::FPTrunc.value, immediate: from_lowir.to_i64!)
      end
      wrap_res(t, to_type, value.pp)
    when {Type::BoolType, Type::IntType}
      t = emit_value(IROp::Convert, to_lowir, val, sub: IRConvert::ZExt.value, immediate: GM.ir_type(IRType::I1).to_i64!)
      wrap_res(t, to_type, value.pp)
    when {Type::PtrType, Type::PtrType}
      wrap_res(val, to_type, value.pp)
    when {Type::IntType, Type::PtrType}
      t = emit_value(IROp::Copy, GM.ir_type(IRType::Ptr), val)
      wrap_res(t, to_type, value.pp)
    when {Type::PtrType, Type::IntType}
      t = emit_value(IROp::Copy, to_lowir, val)
      wrap_res(t, to_type, value.pp)
    when {Type::IntType, Type::Fn}
      t = emit_value(IROp::Copy, GM.ir_type(IRType::Ptr), val)
      wrap_res(t, to_type, value.pp)
    when {Type::Fn, Type::IntType}
      if to_type.bytes_count >= builder.layout.target.pointer_size
        t = emit_value(IROp::Copy, to_lowir, val)
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
    t = none

    case {from_type, to_type}
    when {Type::IntType, Type::IntType}
      from_size = from_type.bytes_count
      to_size = to_type.bytes_count
      if to_size > from_size
        op = from_type.signed ? IRConvert::SExt : IRConvert::ZExt
        t = emit_value(IROp::Convert, to_lowir, val, sub: op.value, immediate: from_lowir.to_i64!)
        wrap_res(t, to_type, value.pp)
      elsif to_size == from_size && from_type.signed == to_type.signed
        wrap_res(val, to_type, value.pp)
      end
    when {Type::IntType, Type::FloatType}
      if to_type.bytes_count >= from_type.bytes_count
        op = from_type.signed ? IRConvert::SIToFP : IRConvert::UIToFP
        t = emit_value(IROp::Convert, to_lowir, val, sub: op.value, immediate: from_lowir.to_i64!)
        wrap_res(t, to_type, value.pp)
      end
    when {Type::FloatType, Type::FloatType}
      if to_type.bytes_count > from_type.bytes_count
        t = emit_value(IROp::Convert, to_lowir, val, sub: IRConvert::FPExt.value, immediate: from_lowir.to_i64!)
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
      field_ptr = none
      field_ptr = emit_value(IROp::Index, GM.ir_type(IRType::I8), base, byte_offset, order: IRIndexBounds::InBounds.value)
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
                  extension = index_type.signed ? IRConvert::SExt : IRConvert::ZExt
                  emit_value(IROp::Convert, GM.ir_type(IRType::I64), idx, sub: extension.value, immediate: lowir_type(index_type).to_i64!)
                elsif index_type.bytes_count > 8
                  emit_value(IROp::Convert, GM.ir_type(IRType::I64), idx, sub: IRConvert::Trunc.value, immediate: lowir_type(index_type).to_i64!)
                else
                  idx
                end
              else
                idx
              end
    t = none
    t = emit_value(IROp::Index, lowir_type(target_type), ptr_val, idx_val, order: IRIndexBounds::InBounds.value)
    wrap_val(t, value.type, value.pp)
  end

  def bitcast(value : Value, to_type : Type) : Value
    wrap_ref(lowir_val(value), to_type, value.pp)
  end

  def va_start(arg : Value, val : Value)
    emit(none, IROp::VaStart, a: addr_or_val(arg))
  end

  def va_end(arg : Value)
  end

  def va_arg(arg : Value, type : Type) : Value
    t = none
    t = emit_value(IROp::VaArg, lowir_type(type), addr_or_val(arg))
    wrap_res(t, type, arg.pp)
  end

  def builder
    @builder.as(Builder)
  end

  private def none : LibGM::Value
    GM.ir_value(IRKind::None)
  end

  private def block_value(bb : AbstractBB) : LibGM::Value
    GM.ir_value(IRKind::Block, bb.as(BB).id)
  end

  private def operand(value : LibGM::Value) : LibGM::Value
    value
  end

  private def operand(value : Int) : LibGM::Value
    func.integer(value)
  end

  def emit_value(op : IROp, type : UInt64 = 0_u64,
                 a : LibGM::Value | Int = LibGM::Value.new, b : LibGM::Value | Int = LibGM::Value.new,
                 c : LibGM::Value | Int = LibGM::Value.new, sub : UInt8 = 0_u8,
                 immediate : Int64 = 0_i64, flags : UInt8 = 0_u8, order : UInt8 = 0_u8,
                 extra_first : UInt32 = 0_u32, extra_count : UInt32 = 0_u32) : LibGM::Value
    return none if @terminated || @id == NO_ID
    # Materialize operands before allocating the result: they may append
    # literals or addresses and grow the same native buffers.
    aa, bb, cc = operand(a), operand(b), operand(c)
    result = func.new_temp
    emit_record(result.index, op, type, aa, bb, cc, sub, immediate, flags, order, extra_first, extra_count)
    result
  end

  def emit(result : LibGM::Value, op : IROp, type : UInt64 = 0_u64,
           a : LibGM::Value | Int = LibGM::Value.new, b : LibGM::Value | Int = LibGM::Value.new,
           c : LibGM::Value | Int = LibGM::Value.new, sub : UInt8 = 0_u8,
           immediate : Int64 = 0_i64, flags : UInt8 = 0_u8, order : UInt8 = 0_u8,
           extra_first : UInt32 = 0_u32, extra_count : UInt32 = 0_u32)
    return if @terminated || @id == NO_ID
    emit_record(NO_ID, op, type, operand(a), operand(b), operand(c), sub, immediate, flags, order, extra_first, extra_count)
    @terminated = true if op.value >= IROp::Throw.value
  end

  private def emit_record(result, op, type, a, b, c, sub, immediate, flags, order, extra_first, extra_count)
    func.append_instruction(LibGM::Instruction.new(op: op.value, sub: sub, flags: flags, order: order,
      result: result, next: NO_ID, location: @id, type: type, ops: StaticArray[a, b, c],
      extra_first: extra_first, extra_count: extra_count, immediate: immediate))
  end

  def copy_object(source : LibGM::Value, target : LibGM::Value, bytes : UInt64, align : UInt64)
    return if bytes == 0
    emit(none, IROp::CopyObject, a: source, b: target, sub: align.trailing_zeros_count.to_u8, immediate: bytes.to_i64)
  end

  def copy_result(value : Value) : Value
    t = none
    t = emit_value(IROp::Copy, lowir_type(value.type), lowir_val(value))
    wrap_val(t, value.type, value.pp)
  end

  private def lowir_type(v : Value) : UInt64
    lowir_type(v.type)
  end

  private def lowir_type(t : Type) : UInt64
    builder.lowir_type(t)
  end

  def func
    @func.as(Func)
  end

  private def wrap_val(val : LibGM::Value, type : Type, pp : Value::PP) : Value
    Value.new(BBVal.new(val), type, Value::MM::Val, pp)
  end

  private def wrap_ref(val : LibGM::Value, type : Type, pp : Value::PP) : Value
    Value.new(BBVal.new(val), type, Value::MM::Ref, pp)
  end

  private def wrap_res(val : LibGM::Value, type : Type, pp : Value::PP) : Value
    wrap_val(val, type, pp)
  end

  private def typer : Typer
    @func_def.mod.typer
  end

  private def libm_call(name : String, ret_type : Type, args : Array(Value)) : LibGM::Value
    type_fn = Type::Fn.new(Location.new("", 0), args.map(&.type), ret_type)
    call(name, type_fn, args).not_nil!.bbval.as(BBVal).val
  end

  def _lowir_val(value : Value) : LibGM::Value
    value.bbval.as(BBVal).val
  end

  def lowir_val(value : Value) : LibGM::Value
    # A symbol operand already denotes its address in LowIR. Do not emit
    # a temporary Addr for strings, function pointers or global addresses.
    _lowir_val(value)
  end

  private def addr_or_val(value : Value) : LibGM::Value
    raw = _lowir_val(value)
    if raw.kind == IRKind::Slot.value
      emit_value(IROp::Addr, GM.ir_type(IRType::Ptr), raw)
    else
      raw
    end
  end
end
