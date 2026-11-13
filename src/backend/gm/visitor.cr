class Myc::Backend::GM::Visitor < Myc::Backend::AbstractVisitor
  def visit(op : Opcode::Ret)
    # Scalar results are already SSA values. Returning them directly avoids
    # a slot, stores/loads and an exit join for the optimizer to undo. Blit
    # results retain their owned result storage and aggregate ABI handling.
    if @func_def.type_fn.ret.needs_blit?
      super
    else
      @bb.ret(@func_def.have_ret? ? pop_return_value(@func_def.type_fn.ret) : nil)
      @bb = dummy_bb
    end
  end

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
