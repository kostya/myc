abstract class Myc::Backend::AbstractFunc
  getter builder : AbstractBuilder
  getter func_def : Mod::FuncDef
  getter header_mod : Mod

  getter! alloca_bb : AbstractBB?
  getter! body_bb : AbstractBB?
  getter! ret_bb : AbstractBB?

  getter bbs : Hash(String, AbstractBB)
  getter result : Value?

  def initialize(@builder, @func_def, @header_mod)
    @bbs = Hash(String, AbstractBB).new
    @alloca_bb = new_raw_bb("alloca")
    @body_bb = new_raw_bb("body")
    @ret_bb = new_raw_bb("ret")

    if func_def.have_ret?
      name = "__myc_result"
      @result = res = alloca_bb.alloca(name, func_def.type_fn.ret)
      res.pp = Value::PP::Local.new(name)
    end
  end

  def build
    v = new_visitor
    v.visit
    finish(v)
  end

  def finish(v : AbstractVisitor)
    alloca_bb.jmp(body_bb)
    v.bb.jmp(ret_bb)
    v.bb = ret_bb
    ret_bb.ret(result.try &.to_rhs(v))
  end

  def new_bb(name : String) : AbstractBB
    name = builder.new_label(name)
    @bbs[name] = new_raw_bb(name, @bbs.size)
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
