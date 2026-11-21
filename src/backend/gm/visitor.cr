class Myc::Backend::GM::Visitor < Myc::Backend::AbstractVisitor
  def visit(op : Opcode::Field)
    value = last
    self << pop.ensure_ref(self) if value.mm.val? && value.type.needs_blit?
    super
  end
end
