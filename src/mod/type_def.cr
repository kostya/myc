class Myc::Mod::TypeDef
  property node : Source::Node
  property type : Type
  property mod : Mod

  def initialize(@mod, @node, @type)
  end
end
