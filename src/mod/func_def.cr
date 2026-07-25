class Myc::Mod::FuncDef
  property node : Source::Node
  property mod : Mod
  property name : String
  property type_fn : Type::Fn
  property body : Opcode::Seq? = nil

  property inline_stats : Inliner::Stats

  @[Flags]
  enum Attr
    Noinline
    Vaarg
    Private
  end

  property attrs : Attr

  def initialize(@node, @mod, @name, @type_fn, @attrs = Attr.new(0))
    @inline_stats = Inliner::Stats.new(@name)
  end

  def have_ret?
    !type_fn.ret.eq?(mod.typer.void)
  end

  def deep_walk(&block : Opcode ->)
    body.try &.deep_walk(&block)
  end

  def private?
    @attrs.includes?(Attr::Private)
  end
end
