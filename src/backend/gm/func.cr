class Myc::Backend::GM::Func < Myc::Backend::AbstractFunc
  getter temp_counter : UInt32
  getter operand_count = 0_u32
  @instruction_count = 0_u32
  @literal_count = 0_u32
  @slot_count = 0_u32
  @block_count = 0_u32
  @buffers = LibGM::BodyBuffers.new
  @symbol : UInt32

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
    if @literal_count == @buffers.capacity.literals
      reserve(@instruction_count, @operand_count, @literal_count + 1, @slot_count, @block_count)
    end
    id = @literal_count
    @buffers.literals.as(LibGM::Literal*)[id] = LibGM::Literal.new(low: low, high: high)
    @literal_count += 1
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
      alloca_bb.jmp(body_bb)
      visitor.bb.jmp(ret_bb)
      ret = ret_bb.as(BB)
      if res = result
        ret.ret(res.type.needs_blit? ? ret.copy_result(res) : ret.load_return(res))
      else
        ret.ret(nil)
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
    layout[0] = alloca_bb.as(BB).id
    layout[1] = body_bb.as(BB).id
    at = 2
    @bbs.each do |name, bb|
      next if {"alloca", "body", "ret", "__myc_dummy_bb__"}.includes?(name)
      layout[at] = bb.as(BB).id
      at += 1
    end
    layout[at] = ret_bb.as(BB).id
    raise "GM block layout mismatch" unless at + 1 == @block_count
    counts = LibGM::BodyCounts.new(instructions: @instruction_count, operands: @operand_count,
      literals: @literal_count, slots: @slot_count, blocks: @block_count)
    builder.check(NativeAPI.commit(builder.handle, @symbol, pointerof(counts), @temp_counter))
  end
end
