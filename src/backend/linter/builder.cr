class Myc::Backend::Linter::Builder < Myc::Backend::AbstractBuilder
  @global_links = Hash(String, Value).new
  property notes = Hash(Opcode, String).new

  def global_register(mod : Mod, global : Mod::GlobalDef)
    if global.initial_keyword
      if global.initial_values.size > 0
        vp = AbstractBuilder::ValuesParser.new(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
        init_value(vp.parse)
      end
    end

    @global_links[global.name] = Value.new(BB::FAKE_VAL, global.type, Value::MM::Ref, global.constant ? Value::PP::GlobalConstant.new(global.name) : Value::PP::Global.new(global.name))
  end

  def init_value(ival : InitValue) : Value
    Value.new(BB::FAKE_VAL, ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  def func_register(name : String, func_def : Mod::FuncDef)
  end

  def find_global(name : String) : Value?
    @global_links[name]?
  end

  def new_func(func_def : Mod::FuncDef, header_mod : Mod) : AbstractFunc
    Func.new(self, func_def, header_mod)
  end
end
