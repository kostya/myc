class Myc::Mod::GlobalDef
  property node : Source::Node
  property mod : Mod
  property name : String
  property type : Type
  property initial_keyword : Bool
  property initial_values : Array(Source::Token::Value)
  property constant : Bool
  property private_flag : Bool

  def initialize(@mod, @node, @name, @type, @initial_keyword, @initial_values, @constant = false, @private_flag = false)
  end
end
