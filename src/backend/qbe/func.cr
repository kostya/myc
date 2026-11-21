class Myc::Backend::QBE::Func < Myc::Backend::AbstractFunc
  getter temp_counter : Int32
  getter body_io : IO::Memory

  def initialize(@builder : Builder, @func_def : Mod::FuncDef, @header_mod : Mod)
    super(@builder, @func_def, @header_mod)
    @temp_counter = 0
    @body_io = IO::Memory.new
  end

  def bb_class : AbstractBB.class
    BB
  end

  def visitor_class : AbstractVisitor.class
    Visitor
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
    type_fn = @func_def.type_fn
    visibility = "export "
    @func_def.attrs.each do |attr|
      case attr
      when Mod::FuncDef::Attr::Private
        visibility = ""
      end
    end

    ret_type = builder.qbe_type(type_fn.ret)
    args = type_fn.args.map_with_index { |t, i| "#{builder.qbe_type(t)} %arg#{i}" }

    vaarg_str = if type_fn.vaarg
                  if type_fn.args.empty?
                    "..."
                  else
                    ", ..."
                  end
                end

    emit "#{visibility}function #{ret_type} $#{@func_def.name}(#{args.join(", ")}#{vaarg_str}) {\n"
    emit "@start\n"

    v = new_visitor
    v.visit

    alloca_bb.as(BB).copy_data(body_io, false)

    emit "  jmp @body\n"

    body_bb.as(BB).copy_data(body_io, true)
    @all_bbs.each &.as(BB).copy_data(body_io, true)

    emit "}\n\n"
  end

  def new_temp : String
    @temp_counter += 1
    "%t#{@temp_counter}"
  end
end
