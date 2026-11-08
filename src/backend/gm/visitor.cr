class Myc::Backend::GM::Visitor < Myc::Backend::AbstractVisitor
  def visit(op : Opcode::Field)
    value = last
    if value.type.needs_blit?
      ref = value._to_ref(self)
      @stack.pop
      @stack << ref
    end
    super
  end
end
