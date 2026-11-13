class Myc::Backend::GM::Func < Myc::Backend::AbstractFunc
  getter temp_counter : UInt32
  getter operand_count = 0_u32
  @instruction_count = 0_u32
  @literal_count = 0_u32
  @slot_count = 0_u32
  @block_count = 0_u32
  @buffers = LibGM::BodyBuffers.new
  @symbol : UInt32
  @zero_literal = NO_ID
  @one_literal = NO_ID
  @minus_one_literal = NO_ID

  def initialize(@builder : Builder, @func_def : Mod::FuncDef, @header_mod : Mod)
    @temp_counter = @func_def.type_fn.args.size.to_u32
    @symbol = @builder.as(Builder).symbol(@func_def.name)
    # Storage belongs to cppgm from the first write. Growing a function may
    # relocate its buffers; only IDs survive a reserve call, never pointers.
    hint = {@func_def.inline_stats.inst_count + 16, 32}.max
    reserve({hint, 65536}.min, 16, 16, 8, 8)
    super(@builder, @func_def, @header_mod)
  end

  private def reserve(instructions, operands, literals, slots, blocks)
    cap = @buffers.capacity
    return if instructions <= cap.instructions && operands <= cap.operands && literals <= cap.literals && slots <= cap.slots && blocks <= cap.blocks
    minimum = LibGM::BodyCounts.new(instructions: instructions.to_u32, operands: operands.to_u32,
      literals: literals.to_u32, slots: slots.to_u32, blocks: blocks.to_u32)
    @builder.as(Builder).check(NativeAPI.reserve(@builder.as(Builder).handle, @symbol, pointerof(minimum), pointerof(@buffers)))
  end

  protected def new_body_bb : AbstractBB
    # Slots are function-owned records, not entry-block instructions. Incoming
    # aggregate copies are emitted by params before visiting the body, so both
    # kinds of setup can share the first block with ordinary instructions.
    alloca_bb
  end

  protected def new_return_bb : AbstractBB?
    new_raw_bb("ret") if needs_result_slot?
  end

  protected def needs_result_slot? : Bool
    @func_def.have_ret? && @func_def.type_fn.ret.needs_blit?
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

  def next_block : UInt32
    if @block_count == @buffers.capacity.blocks
      reserve(@instruction_count, @operand_count, @literal_count, @slot_count, @block_count + 1)
    end
    id = @block_count
    @block_count += 1
    id
  end

  def slot(type : UInt64) : LibGM::Value
    if @slot_count == @buffers.capacity.slots
      reserve(@instruction_count, @operand_count, @literal_count, @slot_count + 1, @block_count)
    end
    id = @slot_count
    @buffers.slots.as(LibGM::Slot*)[id] = LibGM::Slot.new(type: type)
    @slot_count += 1
    GM.ir_value(IRKind::Slot, id)
  end

  def new_temp : LibGM::Value
    id = @temp_counter
    @temp_counter += 1
    GM.ir_value(IRKind::Temp, id)
  end

  def literal(kind : IRKind, low : UInt64, high = 0_u64, float_type = IRType::Void) : LibGM::Value
    # Pool entries contain only bits: integer and floating uses can share
    # them. Cache the frequent bit patterns without a hash table per function.
    cached = if high == 0
               low == 0 ? @zero_literal : (low == 1 ? @one_literal : NO_ID)
             elsif high == UInt64::MAX && low == UInt64::MAX
               @minus_one_literal
             else
               NO_ID
             end
    return LibGM::Value.new(kind: kind.value, float_kind: float_type.value, index: cached) unless cached == NO_ID
    if @literal_count == @buffers.capacity.literals
      reserve(@instruction_count, @operand_count, @literal_count + 1, @slot_count, @block_count)
    end
    id = @literal_count
    @buffers.literals.as(LibGM::Literal*)[id] = LibGM::Literal.new(low: low, high: high)
    @literal_count += 1
    if high == 0
      @zero_literal = id if low == 0
      @one_literal = id if low == 1
    elsif high == UInt64::MAX && low == UInt64::MAX
      @minus_one_literal = id
    end
    LibGM::Value.new(kind: kind.value, float_kind: float_type.value, index: id)
  end

  def integer(value : Int) : LibGM::Value
    literal(IRKind::Integer, value.to_u64!, value < 0 ? UInt64::MAX : 0_u64)
  end

  def append_operand(value : LibGM::Value)
    if @operand_count == @buffers.capacity.operands
      reserve(@instruction_count, @operand_count + 1, @literal_count, @slot_count, @block_count)
    end
    @buffers.operands.as(LibGM::Value*)[@operand_count] = value
    @operand_count += 1
  end

  def append_instruction(instruction : LibGM::Instruction)
    if @instruction_count == @buffers.capacity.instructions
      reserve(@instruction_count + 1, @operand_count, @literal_count, @slot_count, @block_count)
    end
    @buffers.instructions.as(LibGM::Instruction*)[@instruction_count] = instruction
    @instruction_count += 1
  end

  def params : Array(Value)
    @func_def.type_fn.args.map_with_index do |type, index|
      raw = GM.ir_value(IRKind::Temp, index.to_u32)
      if type.needs_blit?
        name = "__myc_blit_arg_#{index}"
        bb = alloca_bb.as(BB)
        slot_ref = bb.alloca(name, type)
        slot_ref.pp = Value::PP::Local.new(name)
        home = bb.emit_value(IROp::Addr, GM.ir_type(IRType::Ptr), bb.lowir_val(slot_ref))
        bb.copy_object(raw, home, builder.layout.size_of(type), builder.layout.alignment_of(type))
        slot_ref
      else
        Value.new(BBVal.new(raw), type, Value::MM::Val, Value::PP::Param.new(index))
      end
    end
  end

  def build
    previous = builder.current_func
    builder.current_func = self
    begin
      visitor = new_visitor
      visitor.visit
      if res = result
        visitor.bb.jmp(ret_bb)
        ret = ret_bb.as(BB)
        ret.ret(ret.copy_result(res))
      elsif @func_def.have_ret?
        # A reachable fallthrough of a value-returning function had an
        # undefined result already. Do not create a separate block for it.
        visitor.bb.as(BB).unreachable
      else
        visitor.bb.ret(nil)
      end
      submit
    ensure
      builder.current_func = previous
    end
  end

  private def submit
    # Only the layout is finalized here. Records are already in cppgm's
    # pools; IDs were allocated when definitions were emitted, with no holes.
    layout = @buffers.layout.as(UInt32*)
    layout[0] = body_bb.as(BB).id
    at = 1
    @bbs.each_value do |bb|
      layout[at] = bb.as(BB).id
      at += 1
    end
    if ret = @ret_bb
      layout[at] = ret.as(BB).id
      at += 1
    end
    raise "GM block layout mismatch" unless at == @block_count
    counts = LibGM::BodyCounts.new(instructions: @instruction_count, operands: @operand_count,
      literals: @literal_count, slots: @slot_count, blocks: @block_count)
    builder.check(NativeAPI.commit(builder.handle, @symbol, pointerof(counts), @temp_counter))
  end
end
