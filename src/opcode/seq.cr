# Seq - Sequence Container (Internal)
#
# Ordered list of opcodes. Used for function bodies, branches, loop sections.
# Not an opcode itself - created automatically by the parser.
#
class Myc::Opcode::Seq < Myc::Opcode
  property list = Array(Opcode).new
  property stack_balance = 0

  def <<(op : Opcode)
    @list << op
  end

  def <<(ops : Array(Opcode))
    @list += ops
  end

  def deep_walk(&block : Opcode ->)
    list.each do |op|
      block.call(op)
      case op
      when Opcode::If
        op.then_seq.deep_walk(&block)
        op.else_seq.deep_walk(&block)
      when Opcode::Loop
        op.init_seq.deep_walk(&block)
        op.cond_seq.deep_walk(&block)
        op.body_seq.deep_walk(&block)
        op.step_seq.deep_walk(&block)
      when Opcode::Switch
        op.cases_seq.each { |seq| seq.deep_walk(&block) }
        op.else_seq.deep_walk(&block)
      end
    end
  end
end
