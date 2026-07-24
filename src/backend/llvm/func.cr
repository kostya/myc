class Myc::Backend::Llvm::Func < Myc::Backend::AbstractFunc
  getter link : FuncLink

  def builder
    @builder.as(Builder)
  end

  def initialize(@builder, @func_def, @header_mod)
    @link = builder.func_link(func_def.name, func_def.type_fn)
    func_def.attrs.each do |attr|
      case attr
      when Mod::FuncDef::Attr::Noinline
        @link.llvm_function.add_attribute LLVM::Attribute::NoInline
      when Mod::FuncDef::Attr::Private
        @link.llvm_function.linkage = LLVM::Linkage::Private
      end
    end
    unless builder.backend.common_options.final
      @link.llvm_function.add_attribute LLVM::Attribute::NoInline
    end
    super
  end

  def new_bb(name : String) : AbstractBB
    BB.new(name, @builder, self, @func_def)
  end

  def new_visitor : AbstractVisitor
    Visitor.new(@builder, self, body_bb, func_def, func_def.mod, @header_mod, params)
  end

  def finish(v : AbstractVisitor)
    super
    v.fake_bb.as(BB).llvm_bb.delete
  end

  private def params : Array(Value)
    res = Array(Value).new
    link.llvm_function.params.each_with_index do |param, index|
      val = BBVal.new(param)
      type = @func_def.type_fn.args[index]
      res << Value.new(val, type, Value::MM::Val, Value::PP::Param.new(index))
    end
    res
  end
end
