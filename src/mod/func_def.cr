class Myc::Mod::FuncDef
  property node : Source::Node
  property mod : Mod
  property name : String
  property type_fn : Type::Fn
  property body : Opcode::Seq? = nil
  property attributes : Array(String)? = nil
  property inline_stats : Inliner::Stats

  def initialize(@node, @mod, @name, @type_fn, @attributes = nil)
    @inline_stats = Inliner::Stats.new(@name)
  end

  def have_ret?
    !type_fn.ret.eq?(mod.typer.void)
  end

  def deep_walk(&block : Opcode ->)
    body.try &.deep_walk(&block)
  end
end
