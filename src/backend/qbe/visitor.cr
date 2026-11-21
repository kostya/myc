class Myc::Backend::QBE::Visitor < Myc::Backend::AbstractVisitor
  protected def add_auto_ret
    if func_def.have_ret?
      visit Opcode::Local.new("__myc_result__", func_def.type_fn.ret)
      @bb.as(BB).emit "call $memset(l %__myc_result__, w 0, l #{builder.layout.size_of(func_def.type_fn.ret)})"
    end
    visit Opcode::Ret.new
  end
end
