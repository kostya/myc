class Myc::Backend::Linter::Visitor < Myc::Backend::AbstractVisitor
  def visit_child(child : Opcode)
    return if (@bb == @dummy_bb) && !child.is_a?(Opcode::Label)
    Myc.debug(:visitor) { "visit #{child.inspect}" }
    @instruction_id += 1
    @current_op = child
    visit(child)
    builder.as(Builder).notes[child] = debug_stack
  end
end
