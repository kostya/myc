class Myc::Backend::GM::Visitor < Myc::Backend::AbstractVisitor
  def visit(op : Opcode::Field)
    value = last
    self << ensure_ref(pop) if value.val? && value.type.needs_blit?
    super
  end
end
