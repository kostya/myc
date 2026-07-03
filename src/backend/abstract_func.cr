abstract class Myc::Backend::AbstractFunc
  getter builder : AbstractBuilder
  getter func_def : Mod::FuncDef

  getter! alloca_bb : AbstractBB?
  getter! body_bb : AbstractBB?

  def initialize(@builder, @func_def)
    @alloca_bb = new_bb("alloca")
    @body_bb = new_bb("body")
  end

  def build
    v = new_visitor
    v.visit
    finish(v)
  end

  def finish(v : AbstractVisitor)
    alloca_bb.jmp(body_bb)
  end

  abstract def new_bb(name : String) : AbstractBB
  abstract def new_visitor : AbstractVisitor
end
