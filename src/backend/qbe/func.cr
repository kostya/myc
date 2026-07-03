class Myc::Backend::QBE::Func < Myc::Backend::AbstractFunc
  getter temp_counter : Int32
  getter blocks : Array(BB)
  getter body_io : IO::Memory

  def initialize(@builder : Builder, @func_def : Mod::FuncDef)
    super(@builder, @func_def)
    @temp_counter = 0
    @blocks = Array(BB).new
    @body_io = IO::Memory.new
  end

  def new_bb(name : String) : AbstractBB
    BB.new(name, @builder, self, @func_def)
  end

  def new_visitor : AbstractVisitor
    Visitor.new(@builder, self, body_bb, func_def, func_def.mod, params)
  end

  def builder
    @builder.as(Builder)
  end

  def params : Array(Value)
    @func_def.type_fn.args.map_with_index do |type, index|
      Value.new(BBVal.new("%arg#{index}"), type, Value::MM::Val, Value::PP::Param.new(index))
    end
  end

  def emit(s : String)
    @body_io << s
  end

  def build
    @func_def.attributes.try &.each do |attr|
      case attr
      when "noinline"
      else
        raise Error::ErrorLoc.new("unknown attr #{attr}", Location.new(func_def.mod.filename, func_def.node.offset))
      end
    end

    ret_type = builder.qbe_type(@func_def.type_fn.ret)
    args = @func_def.type_fn.args.map_with_index { |t, i| "#{builder.qbe_type(t)} %arg#{i}" }

    emit "export function #{ret_type} $#{@func_def.name}(#{args.join(", ")}) {\n"
    emit "@start\n"

    v = new_visitor
    v.visit

    @alloca_bb.as(BB).copy_data(body_io, false)

    emit "  jmp @body\n"

    @body_bb.as(BB).copy_data(body_io, true)
    @blocks.each &.copy_data(body_io, true)

    emit "}\n\n"
  end

  def new_temp : String
    @temp_counter += 1
    "%t#{@temp_counter}"
  end

  def register_block(bb : BB)
    @blocks << bb
  end
end
