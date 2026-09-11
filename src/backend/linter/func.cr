class Myc::Backend::Linter::Func < Myc::Backend::AbstractFunc
  def initialize(@builder, @func_def, @header_mod)
    super(@builder, @func_def, @header_mod)
  end

  def bb_class : AbstractBB.class
    BB
  end

  def visitor_class : AbstractVisitor.class
    Visitor
  end

  def params : Array(Value)
    @func_def.type_fn.args.map_with_index do |type, index|
      Value.new(BB::FAKE_VAL, type, Value::MM::Val, Value::PP::Param.new(index))
    end
  end

  def build
    v = new_visitor
    v.visit
  end
end
