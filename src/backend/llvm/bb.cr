class Myc::Backend::Llvm::BB < Myc::Backend::AbstractBB
  getter llvm_bb : LLVM::BasicBlock
  getter llvm_builder : LLVM::Builder

  def initialize(@name, @builder, @func, @func_def)
    super

    @llvm_bb = @func.as(Func).link.llvm_function.basic_blocks.append @name
    @llvm_builder = @builder.as(Builder).context.new_builder
    @llvm_builder.position_at_end(@llvm_bb)
    @gc_stackmap_lives = [] of Value
  end

  def alloca(name : String, type : Type) : Value
    ltype = type.is_a?(Type::VaListType) ? builder.valist_llvm_type : llvm_type(type)
    raw = @llvm_builder.alloca(ltype, name)
    slot = wrap_ref(raw, type, Value::PP::LocalUninitialized.new(name))
    if builder.gc_safepoints && type.gc_pointer?
      # Rooted allocas are walked before the first STORE. Garbage bits
      # that happen to look like a heap object get relocated and then
      # used as the local (Parser stack slots, myc spill pool).
      inst = @llvm_builder.store(ltype.null, raw)
      inst.volatile = true
    end
    slot
  end

  def vla(type : Type, ptr_type : Type, size : Value) : Value
    val = @llvm_builder.build_array_alloca(llvm_type(type), llvm_val(size))
    wrap_val(val, ptr_type, Value::PP::Vla.new)
  end

  def load_ref(value : Value) : Value
    if value.type.is_a?(Type::VaListType)
      value
    else
      llvm = if builder.gc_safepoints && value.type.gc_pointer?
               @llvm_builder.load_volatile(llvm_type(value), llvm_val(value))
             else
               @llvm_builder.load(llvm_type(value), llvm_val(value))
             end
      wrap_val(llvm, value.type, value.pp)
    end
  end

  def jmp(other : AbstractBB)
    @llvm_builder.br(other.as(BB).llvm_bb)
  end

  def indirect_jmp(bb_addr : Value, bbs : Array(AbstractBB))
    @llvm_builder.indirect_br(llvm_val(bb_addr), bbs.map &.as(BB).llvm_bb)
  end

  def ret(val : Value?)
    if val
      @llvm_builder.ret(llvm_val(val))
    else
      @llvm_builder.ret
    end
  end

  def call(name : String, type_fn : Type::Fn, args : Array(Value)) : Value?
    lives = take_gc_stackmap_lives
    if !lives.empty?
      link = builder.func_link(name, type_fn)
      target = LLVM::Value.new(link.llvm_function.to_unsafe)
      emitted, wrapped = emit_statepoint_call(target, link.llvm_type, type_fn, args, lives)
      if emitted
        # statepoint records Indirect spills; leftover callee-saved
        # copies still need a post-call clobber so later uses reload.
        emit_gc_reg_clobber(name)
        return wrapped
      end
    end
    link = builder.func_link(name, type_fn)
    vals = args.map { |arg| llvm_val(arg) }
    val = @llvm_builder.call(link.llvm_type, link.llvm_function, vals)
    emit_gc_reg_clobber(name)
    unless type_fn.ret.eq?(func_def.mod.typer.void)
      wrap_val(val, type_fn.ret, Value::PP::CallResult.new(name))
    end
  end

  def gc_set_stackmap_lives(lives : Array(Value))
    @gc_stackmap_lives = lives
  end

  # Opaque reload of rooted pointer allocas after a collecting CALL.
  # The reload helper is an external C function, so isel cannot replace
  # its result with a pre-call heap pointer sitting in an unrooted spill.
  def gc_reload_root_slots(slots : Array(Value))
    return unless builder.gc_safepoints
    return if slots.empty?
    reload = builder.gc_config.reload
    return if reload.empty?
    voidp = func_def.mod.typer.voidp
    type_fn = Type::Fn.new(Location.new("", 0), [voidp], voidp)
    link = builder.func_link(reload, type_fn)
    link.llvm_function.add_attribute LLVM::Attribute::NoInline
    slots.each do |slot|
      next unless slot.type.is_a?(Type::PtrType)
      addr = llvm_val(slot)
      loaded = @llvm_builder.call(link.llvm_type, link.llvm_function, [addr])
      inst = @llvm_builder.store(loaded, addr)
      inst.volatile = true
    end
  end

  def invoke(fn : Value, type_fn : Type::Fn, args : Array(Value)) : Value?
    lives = take_gc_stackmap_lives
    if !lives.empty?
      emitted, wrapped = emit_statepoint_call(llvm_val(fn), fn_signature(type_fn), type_fn, args, lives)
      if emitted
        emit_gc_reg_clobber(nil)
        return wrapped
      end
    end
    vals = args.map { |arg| llvm_val(arg) }
    llvm_function = LLVM::Function.new(llvm_val(fn).to_unsafe)
    val = @llvm_builder.call(fn_signature(type_fn), llvm_function, vals)
    emit_gc_reg_clobber(nil)

    unless type_fn.ret.eq?(func_def.mod.typer.void)
      wrap_val(val, type_fn.ret, Value::PP::CallResult.new("invoke"))
    end
  end

  # After a CALL, LLVM isel can keep a pre-call heap pointer in a GPR.
  # Young copy rewrites allocas, not those GPRs. Clobber them so later
  # uses reload from the volatile rooted slots. Caller-saved copies
  # still need gc_reload_root_slots; this covers callee-saved and
  # leftover caller-saved registers.
  private def emit_gc_reg_clobber(name : String?) : Nil
    return unless builder.gc_safepoints
    return if name && gc_callee_is_leaf?(name)
    return unless builder.layout.target.triple.includes?("x86_64")
    ctx = builder.context
    fty = LLVM::Type.function([] of LLVM::Type, ctx.void)
    constraints = "~{rax},~{rbx},~{rcx},~{rdx},~{rsi},~{rdi},~{r8},~{r9},~{r10},~{r11},~{r12},~{r13},~{r14},~{r15},~{memory}"
    asm_val = fty.inline_asm("", constraints, true, false, false)
    LibLLVM.build_call2(@llvm_builder.to_unsafe, fty.to_unsafe, asm_val.to_unsafe, Pointer(LibLLVM::ValueRef).null, 0, "".to_unsafe)
  end

  private def take_gc_stackmap_lives : Array(Value)
    lives = @gc_stackmap_lives
    @gc_stackmap_lives = [] of Value
    lives
  end

  # Wrap a collecting CALL as gc.statepoint so LLVM spills live heap
  # pointers and records Indirect stackmap locations valid during the
  # callee. statepoint-example treats addrspace(1) as GC pointers, so
  # each live is addrspacecast, relocated, cast back, and stored into
  # the rooted alloca.
  private def emit_statepoint_call(callee : LLVM::Value, callee_fty : LLVM::Type, type_fn : Type::Fn, args : Array(Value), lives : Array(Value)) : {Bool, Value?}
    return {false, nil} if type_fn.ret.needs_blit?
    ctx = builder.context
    as1 = ctx.pointer(1)
    slots = [] of Value
    live_as1 = [] of LLVM::Value
    seen = Set(UInt64).new
    lives.each do |slot|
      next unless slot.type.is_a?(Type::PtrType)
      next unless slot.mm.ref?
      key = llvm_val(slot).to_unsafe.address
      next if seen.includes?(key)
      seen << key
      loaded = @llvm_builder.load_volatile(llvm_type(slot), llvm_val(slot))
      slots << slot
      live_as1 << @llvm_builder.addrspace_cast(loaded, as1)
    end
    return {false, nil} if live_as1.empty?

    pair = llvm_intrinsic("llvm.experimental.gc.statepoint", [ctx.pointer])
    return {false, nil} unless pair
    sp_fn, sp_ty = pair

    sp_args = [
      ctx.int64.const_int(0),
      ctx.int32.const_int(0),
      callee,
      ctx.int32.const_int(args.size),
      ctx.int32.const_int(0),
    ] of LLVM::Value
    args.each { |a| sp_args << llvm_val(a) }
    sp_args << ctx.int32.const_int(0)
    sp_args << ctx.int32.const_int(0)

    tag = "gc-live"
    bundle = LLVM::OperandBundleDef.new(
      LibLLVM.create_operand_bundle(tag, tag.bytesize, live_as1.to_unsafe.as(LibLLVM::ValueRef*), live_as1.size)
    )
    tok = @llvm_builder.call(sp_ty, sp_fn, sp_args, "gcsp", bundle)
    bundle.dispose

    et_kind = LibLLVM.get_enum_attribute_kind_for_name("elementtype", "elementtype".bytesize)
    if et_kind != 0
      et = LibLLVM.create_type_attribute(ctx.to_unsafe, et_kind, callee_fty.to_unsafe)
      LibLLVM.add_call_site_attribute(tok.to_unsafe, 3, et)
    end

    result = nil.as(Value?)
    unless type_fn.ret.eq?(func_def.mod.typer.void)
      ret_ll = llvm_type(type_fn.ret)
      res_pair = llvm_intrinsic("llvm.experimental.gc.result", [ret_ll])
      return {false, nil} unless res_pair
      res_fn, res_ty = res_pair
      raw = @llvm_builder.call(res_ty, res_fn, [tok])
      result = wrap_val(raw, type_fn.ret, Value::PP::CallResult.new("gc.result"))
    end

    rel_pair = llvm_intrinsic("llvm.experimental.gc.relocate", [as1])
    return {false, nil} unless rel_pair
    rel_fn, rel_ty = rel_pair
    slots.each_with_index do |slot, i|
      idx = ctx.int32.const_int(i)
      # Relocate so LLVM spills the pointer at the CALL. Do not store
      # the result back into the rooted alloca: the collector already
      # rewrote that slot via the root hook. A missed stackmap walk
      # would otherwise paste a from-space pointer over the good one.
      @llvm_builder.call(rel_ty, rel_fn, [tok, idx, idx])
    end
    {true, result}
  end

  private def llvm_intrinsic(name : String, overload : Array(LLVM::Type)) : {LLVM::Function, LLVM::Type}?
    id = LibLLVM.lookup_intrinsic_id(name, name.bytesize)
    return nil if id == 0
    refs = overload.map(&.to_unsafe)
    fnv = LibLLVM.get_intrinsic_declaration(
      builder.llvm_mod.to_unsafe, id,
      refs.to_unsafe.as(LibLLVM::TypeRef*), refs.size
    )
    fty = LibLLVM.intrinsic_get_type(
      builder.context.to_unsafe, id,
      refs.to_unsafe.as(LibLLVM::TypeRef*), refs.size
    )
    {LLVM::Function.new(fnv), LLVM::Type.new(fty)}
  end

  private def gc_callee_is_leaf?(name : String) : Bool
    return true if builder.gc_config.leaf?(name)
    if f = func_def.mod.func_defs[name]?
      return true if f.leaf?
    end
    false
  end

  def fn_addr(name : String, type_fn : Type::Fn) : Value
    link = builder.func_link(name, type_fn)
    val = LLVM::Value.new(link.llvm_function.to_unsafe)
    wrap_val(val, type_fn, Value::PP::FnAddress.new(name))
  end

  def bb_addr(bb : AbstractBB) : Value
    val = bb.as(BB).llvm_bb.address
    wrap_val(val, typer.indirect, Value::PP::LabelAddress.new(bb.name))
  end

  def cond(cond : Value, then_bb : AbstractBB, else_bb : AbstractBB)
    @llvm_builder.cond(llvm_val(cond), then_bb.as(BB).llvm_bb, else_bb.as(BB).llvm_bb)
  end

  def select(cond : Value, arg_true : Value, arg_false : Value) : Value
    val = @llvm_builder.select(llvm_val(cond), llvm_val(arg_true), llvm_val(arg_false))
    wrap_val(val, arg_true.type, arg_true.pp)
  end

  def store(lhs : Value, rhs : Value)
    if lhs.type.is_a?(Type::VaListType)
      lhs = wrap_val(llvm_val(lhs), lhs.type.to_unsafe_ptr, lhs.pp)
      rhs = wrap_val(llvm_val(rhs), rhs.type.to_unsafe_ptr, rhs.pp)
      intrinsic_call("llvm.va_copy.p0", typer.void, [lhs, rhs])
    else
      inst = @llvm_builder.store(llvm_val(rhs), llvm_val(lhs))
      if builder.gc_safepoints && lhs.type.gc_pointer?
        inst.volatile = true
      end
    end
  end

  def binary(op : Opcode::Binary::Op, lhs : Value, rhs : Value) : Value?
    ltype = lhs.type
    l = llvm_val(lhs)
    r = llvm_val(rhs)

    case op
    in .add?
      case ltype
      when Type::IntType
        wrap_res(@llvm_builder.add(l, r), ltype, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fadd(l, r), ltype, lhs.pp)
      end
    in .sub?
      case ltype
      when Type::IntType
        wrap_res(@llvm_builder.sub(l, r), ltype, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fsub(l, r), ltype, lhs.pp)
      end
    in .mul?
      case ltype
      when Type::IntType
        wrap_res(@llvm_builder.mul(l, r), ltype, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fmul(l, r), ltype, lhs.pp)
      end
    in .div?
      case t = ltype
      when Type::IntType
        if t.signed
          wrap_res(@llvm_builder.sdiv(l, r), ltype, lhs.pp)
        else
          wrap_res(@llvm_builder.udiv(l, r), ltype, lhs.pp)
        end
      when Type::FloatType
        wrap_res(@llvm_builder.fdiv(l, r), ltype, lhs.pp)
      end
    in .rem?
      case t = ltype
      when Type::IntType
        if t.signed
          wrap_res(@llvm_builder.srem(l, r), ltype, lhs.pp)
        else
          wrap_res(@llvm_builder.urem(l, r), ltype, lhs.pp)
        end
      end
    in .and?
      case ltype
      when Type::IntType, Type::BoolType
        wrap_res(@llvm_builder.and(l, r), ltype, lhs.pp)
      end
    in .or?
      case ltype
      when Type::IntType, Type::BoolType
        wrap_res(@llvm_builder.or(l, r), ltype, lhs.pp)
      end
    in .xor?
      case ltype
      when Type::IntType, Type::BoolType
        wrap_res(@llvm_builder.xor(l, r), ltype, lhs.pp)
      end
    in .shl?
      case ltype
      when Type::IntType, Type::BoolType
        wrap_res(@llvm_builder.shl(l, r), ltype, lhs.pp)
      end
    in .shr?
      case ltype
      when Type::IntType, Type::BoolType
        wrap_res(@llvm_builder.lshr(l, r), ltype, lhs.pp)
      end
    in .sar?
      case ltype
      when Type::IntType, Type::BoolType
        wrap_res(@llvm_builder.ashr(l, r), ltype, lhs.pp)
      end
    in .eq?
      case ltype
      when Type::IntType, Type::BoolType, Type::PtrType, Type::Fn
        wrap_res(@llvm_builder.icmp(LLVM::IntPredicate::EQ, l, r), typer.bool, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fcmp(LLVM::RealPredicate::OEQ, l, r), typer.bool, lhs.pp)
      end
    in .not_eq?
      case ltype
      when Type::IntType, Type::BoolType, Type::PtrType, Type::Fn
        wrap_res(@llvm_builder.icmp(LLVM::IntPredicate::NE, l, r), typer.bool, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fcmp(LLVM::RealPredicate::UNE, l, r), typer.bool, lhs.pp)
      end
    in .less?
      case t = ltype
      when Type::IntType
        pred = t.signed ? LLVM::IntPredicate::SLT : LLVM::IntPredicate::ULT
        wrap_res(@llvm_builder.icmp(pred, l, r), typer.bool, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fcmp(LLVM::RealPredicate::OLT, l, r), typer.bool, lhs.pp)
      end
    in .less_eq?
      case t = ltype
      when Type::IntType
        pred = t.signed ? LLVM::IntPredicate::SLE : LLVM::IntPredicate::ULE
        wrap_res(@llvm_builder.icmp(pred, l, r), typer.bool, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fcmp(LLVM::RealPredicate::OLE, l, r), typer.bool, lhs.pp)
      end
    in .more?
      case t = ltype
      when Type::IntType
        pred = t.signed ? LLVM::IntPredicate::SGT : LLVM::IntPredicate::UGT
        wrap_res(@llvm_builder.icmp(pred, l, r), typer.bool, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fcmp(LLVM::RealPredicate::OGT, l, r), typer.bool, lhs.pp)
      end
    in .more_eq?
      case t = ltype
      when Type::IntType
        pred = t.signed ? LLVM::IntPredicate::SGE : LLVM::IntPredicate::UGE
        wrap_res(@llvm_builder.icmp(pred, l, r), typer.bool, lhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fcmp(LLVM::RealPredicate::OGE, l, r), typer.bool, lhs.pp)
      end
    in .rotl?
      case ltype
      when Type::IntType
        wrap_res(intrinsic_call("llvm.fshl.i#{ltype.bitsize}", ltype, [lhs, lhs, rhs]), ltype, lhs.pp)
      end
    in .rotr?
      case ltype
      when Type::IntType
        wrap_res(intrinsic_call("llvm.fshr.i#{ltype.bitsize}", ltype, [lhs, lhs, rhs]), ltype, lhs.pp)
      end
    in .min?
      case ltype
      when Type::IntType
        prefix = ltype.as(Type::IntType).signed ? "llvm.smin" : "llvm.umin"
        wrap_res(intrinsic_call(prefix + ".i#{ltype.bitsize}", ltype, [lhs, rhs]), ltype, lhs.pp)
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.minnum.f#{ltype.bitsize}", ltype, [lhs, rhs]), ltype, lhs.pp)
      end
    in .max?
      case ltype
      when Type::IntType
        prefix = ltype.as(Type::IntType).signed ? "llvm.smax" : "llvm.umax"
        wrap_res(intrinsic_call(prefix + ".i#{ltype.bitsize}", ltype, [lhs, rhs]), ltype, lhs.pp)
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.maxnum.f#{ltype.bitsize}", ltype, [lhs, rhs]), ltype, lhs.pp)
      end
    in .copysign?
      case ltype
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.copysign.f#{ltype.bitsize}", ltype, [lhs, rhs]), ltype, lhs.pp)
      end
    end
  end

  def unary(op : Opcode::Unary::Op, rhs : Value) : Value?
    v = llvm_val(rhs)
    t = rhs.type

    case op
    in .lnot?
      case t
      when Type::IntType, Type::BoolType
        is_zero = @llvm_builder.icmp(LLVM::IntPredicate::EQ, v, llvm_type(rhs.type).const_int(0))
        wrap_res(@llvm_builder.zext(is_zero, llvm_type(rhs.type)), t, rhs.pp)
      end
    in .bnot?
      case t
      when Type::IntType
        wrap_res(@llvm_builder.not(v), t, rhs.pp)
      end
    in .neg?
      case t
      when Type::IntType
        wrap_res(@llvm_builder.neg(v), t, rhs.pp)
      when Type::FloatType
        wrap_res(@llvm_builder.fneg(v), t, rhs.pp)
      end
    in .abs?
      case t
      when Type::IntType
        wrap_res(intrinsic_call("llvm.abs.i#{t.bitsize}", t, [rhs, value_false]), t, rhs.pp)
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.fabs.f#{t.bitsize}", t, [rhs]), t, rhs.pp)
      end
    in .ceil?
      case t
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.ceil.f#{t.bitsize}", t, [rhs]), t, rhs.pp)
      end
    in .floor?
      case t
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.floor.f#{t.bitsize}", t, [rhs]), t, rhs.pp)
      end
    in .trunc?
      case t
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.trunc.f#{t.bitsize}", t, [rhs]), t, rhs.pp)
      end
    in .nearest?
      case t
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.nearbyint.f#{t.bitsize}", t, [rhs]), t, rhs.pp)
      end
    in .sqrt?
      case t
      when Type::FloatType
        wrap_res(intrinsic_call("llvm.sqrt.f#{t.bitsize}", t, [rhs]), t, rhs.pp)
      end
    in .clz?
      case t
      when Type::IntType
        wrap_res(intrinsic_call("llvm.ctlz.i#{t.bitsize}", t, [rhs, value_false]), t, rhs.pp)
      end
    in .ctz?
      case t
      when Type::IntType
        wrap_res(intrinsic_call("llvm.cttz.i#{t.bitsize}", t, [rhs, value_false]), t, rhs.pp)
      end
    in .popcnt?
      case t
      when Type::IntType
        wrap_res(intrinsic_call("llvm.ctpop.i#{t.bitsize}", t, [rhs]), t, rhs.pp)
      end
    end
  end

  def switch(index : Value, case_values : Array(Value), case_bbs : Array(AbstractBB), default_bb : AbstractBB)
    case_map = {} of LLVM::Value => LLVM::BasicBlock
    case_values.each_with_index do |val, i|
      case_map[llvm_val(val)] = case_bbs[i].as(BB).llvm_bb
    end
    @llvm_builder.switch(llvm_val(index), default_bb.as(BB).llvm_bb, case_map)
  end

  def cast?(value : Value, from_type : Type, to_type : Type) : Value?
    v = llvm_val(value)
    tt = llvm_type(to_type)

    case {from_type, to_type}
    when {Type::IntType, Type::IntType}
      from_size = from_type.bytes_count
      to_size = to_type.bytes_count

      val = if to_size == from_size
              v
            elsif to_size > from_size
              if from_type.signed
                @llvm_builder.sext(v, tt)
              else
                @llvm_builder.zext(v, tt)
              end
            else
              @llvm_builder.trunc(v, tt)
            end
      wrap_res(val, to_type, value.pp)
    when {Type::IntType, Type::FloatType}
      val = if from_type.signed
              @llvm_builder.si2fp(v, tt)
            else
              @llvm_builder.ui2fp(v, tt)
            end
      wrap_res(val, to_type, value.pp)
    when {Type::FloatType, Type::IntType}
      val = if to_type.signed
              @llvm_builder.fp2si(v, tt)
            else
              @llvm_builder.fp2ui(v, tt)
            end
      wrap_res(val, to_type, value.pp)
    when {Type::FloatType, Type::FloatType}
      val = if to_type.bytes_count > from_type.bytes_count
              @llvm_builder.fpext(v, tt)
            else
              @llvm_builder.fptrunc(v, tt)
            end
      wrap_res(val, to_type, value.pp)
    when {Type::BoolType, Type::IntType}
      val = @llvm_builder.zext(v, tt)
      wrap_res(val, to_type, value.pp)
    when {Type::PtrType, Type::PtrType}
      wrap_res(v, to_type, value.pp)
    when {Type::IntType, Type::PtrType}
      val = @llvm_builder.int2ptr(v, tt)
      wrap_res(val, to_type, value.pp)
    when {Type::PtrType, Type::IntType}
      if to_type.bytes_count >= builder.layout.target.pointer_size
        val = @llvm_builder.ptr2int(v, tt)
        wrap_res(val, to_type, value.pp)
      end
    when {Type::IntType, Type::Fn}
      val = @llvm_builder.int2ptr(v, tt)
      wrap_res(val, to_type, value.pp)
    when {Type::Fn, Type::IntType}
      if to_type.bytes_count >= builder.layout.target.pointer_size
        val = @llvm_builder.ptr2int(v, tt)
        wrap_res(val, to_type, value.pp)
      end
    when {Type::PtrType, Type::Fn}
      if from_type.target_type.eq?(typer.void)
        wrap_res(v, to_type, value.pp)
      end
    when {Type::Fn, Type::PtrType}
      if to_type.target_type.eq?(typer.void)
        wrap_res(v, to_type, value.pp)
      end
    end
  end

  def to?(value : Value, from_type : Type, to_type : Type) : Value?
    v = llvm_val(value)
    tt = llvm_type(to_type)

    case {from_type, to_type}
    when {Type::IntType, Type::IntType}
      from_size = from_type.bytes_count
      to_size = to_type.bytes_count

      if to_size > from_size
        val = if from_type.signed
                @llvm_builder.sext(v, tt)
              else
                @llvm_builder.zext(v, tt)
              end
        wrap_res(val, to_type, value.pp)
      elsif to_size == from_size && from_type.signed == to_type.signed
        wrap_res(v, to_type, value.pp)
      end
    when {Type::IntType, Type::FloatType}
      if to_type.bytes_count >= from_type.bytes_count
        val = if from_type.signed
                @llvm_builder.si2fp(v, tt)
              else
                @llvm_builder.ui2fp(v, tt)
              end
        wrap_res(val, to_type, value.pp)
      end
    when {Type::FloatType, Type::FloatType}
      if to_type.bytes_count >= from_type.bytes_count
        if to_type.bytes_count > from_type.bytes_count
          val = @llvm_builder.fpext(v, tt)
          wrap_res(val, to_type, value.pp)
        else
          wrap_res(v, to_type, value.pp)
        end
      end
    when {Type::PtrType, Type::PtrType}
      if to_type.target_type.is_a?(Type::VoidType)
        wrap_res(v, to_type, value.pp)
      end
    when {Type::IndirectType, Type::PtrType}
      if to_type.target_type.is_a?(Type::VoidType)
        wrap_res(v, to_type, value.pp)
      end
    when {Type::PtrType, Type::IndirectType}
      if from_type.target_type.is_a?(Type::VoidType)
        wrap_res(v, to_type, value.pp)
      end
    end
  end

  def field(value : Value, field_type : Type, offset : Int32) : Value
    gep = @llvm_builder.inbounds_gep(llvm_type(value.type), llvm_val(value), builder.context.int32.const_int(0), builder.context.int32.const_int(offset))
    wrap_ref(gep, field_type, value.pp)
  end

  def extract_value(value : Value, field_type : Type, offset : Int32) : Value
    val = @llvm_builder.extract_value(llvm_val(value), offset.to_u32)
    wrap_val(val, field_type, value.pp)
  end

  def deref(value : Value, target_type : Type) : Value
    wrap_ref(llvm_val(value), target_type, value.pp)
  end

  def addr(value : Value, ptr_type : Type) : Value
    wrap_val(llvm_val(value), ptr_type, value.pp)
  end

  def offset(value : Value, target_type : Type, offset : Value) : Value
    gep = @llvm_builder.inbounds_gep(llvm_type(target_type), llvm_val(value), llvm_val(offset))
    wrap_val(gep, value.type, value.pp)
  end

  def bitcast(value : Value, to_type : Type) : Value
    wrap_ref(llvm_val(value), to_type, value.pp)
  end

  def va_start(arg : Value, val : Value)
    arg = wrap_val(llvm_val(arg), arg.type.to_unsafe_ptr, arg.pp)
    intrinsic_call("llvm.va_start.p0", typer.void, [arg])
  end

  def va_end(arg : Value)
    arg = wrap_val(llvm_val(arg), arg.type.to_unsafe_ptr, arg.pp)
    intrinsic_call("llvm.va_end.p0", typer.void, [arg])
  end

  def va_arg(arg : Value, type : Type) : Value
    arg = wrap_val(llvm_val(arg), arg.type.to_unsafe_ptr, arg.pp)
    wrap_res(@llvm_builder.va_arg(llvm_val(arg), llvm_type(type)), type, arg.pp)
  end

  private def builder
    @builder.as(Builder)
  end

  private def llvm_val(value : Value) : LLVM::Value
    value.bbval.as(BBVal).llvm
  end

  private def llvm_type(value : Value) : LLVM::Type
    llvm_type(value.type)
  end

  private def llvm_type(t : Type) : LLVM::Type
    builder.llvm_type(t)
  end

  private def wrap_val(llvm : LLVM::Value, type : Type, pp : Value::PP) : Value
    Value.new(BBVal.new(llvm), type, Value::MM::Val, pp)
  end

  private def wrap_ref(llvm : LLVM::Value, type : Type, pp : Value::PP) : Value
    Value.new(BBVal.new(llvm), type, Value::MM::Ref, pp)
  end

  private def wrap_res(llvm : LLVM::Value, type : Type, pp : Value::PP) : Value
    wrap_val(llvm, type, pp)
  end

  private def typer : Typer
    @func_def.mod.typer
  end

  private def fn_signature(type_fn : Type::Fn) : LLVM::Type
    arg_types = type_fn.args.map { |t| llvm_type(t) }
    ret_type = llvm_type(type_fn.ret)
    LLVM::Type.function(arg_types, ret_type, type_fn.vaarg)
  end

  private def intrinsic_link(name : String, ret_type : Type, arg_types : Array(Type)) : FuncLink
    fname = name
    type_fn = Type::Fn.new(Location.new("", 0), arg_types, ret_type)
    builder.func_link(fname, type_fn)
  end

  private def intrinsic_call(name : String, ret_type : Type, args : Array(Value)) : LLVM::Value
    arg_types = args.map { |a| a.type }
    link = intrinsic_link(name, ret_type, arg_types)
    @llvm_builder.call(link.llvm_type, link.llvm_function, args.map { |a| llvm_val(a) })
  end

  private def value_false : Value
    Value.new(BBVal.new(llvm_type(typer.bool).const_int(0)), typer.bool, Value::MM::Val, Value::PP::Primitive.new)
  end
end
