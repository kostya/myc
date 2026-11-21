abstract class Myc::Backend::AbstractFunc
  getter builder : AbstractBuilder
  getter func_def : Mod::FuncDef
  getter header_mod : Mod

  getter! alloca_bb : AbstractBB?
  getter! body_bb : AbstractBB?

  getter all_bbs : Array(AbstractBB)

  def initialize(@builder, @func_def, @header_mod)
    @all_bbs = Array(AbstractBB).new
    @alloca_bb = new_raw_bb("alloca")
    @body_bb = new_raw_bb("body")
  end

  def build
    v = new_visitor
    v.visit
    finish(v)
  end

  def finish(v : AbstractVisitor)
    alloca_bb.jmp(body_bb)
  end

  def new_bb(name : String) : AbstractBB
    name = builder.new_label(name)
    bb = new_raw_bb(name, @all_bbs.size)
    @all_bbs << bb
    bb
  end

  def new_raw_bb(name : String, number : Int32 = 0) : AbstractBB
    bb = bb_class.new(name, @builder, self, @func_def)
    bb.number = number
    bb
  end

  def new_visitor : AbstractVisitor
    visitor_class.new(@builder, self, body_bb, func_def, func_def.mod, @header_mod, params)
  end

  abstract def bb_class : AbstractBB.class
  abstract def visitor_class : AbstractVisitor.class
  abstract def params : Array(Value)
end
