class Myc::Backend::C::Func < Myc::Backend::AbstractFunc
  getter body_io : IO::Memory

  def initialize(@builder, @func_def, @header_mod)
    super(@builder, @func_def, @header_mod)
    @blocks = Array(BB).new
    @body_io = IO::Memory.new
  end

  def builder
    @builder.as(Builder)
  end

  def new_bb(name : String) : AbstractBB
    BB.new(name, @builder, self, @func_def)
  end

  def new_visitor : AbstractVisitor
    Visitor.new(@builder, self, body_bb, func_def, func_def.mod, @header_mod, params)
  end

  def params : Array(Value)
    @func_def.type_fn.args.map_with_index do |type, index|
      Value.new(BBVal.new("arg#{index}"), type, Value::MM::Val, Value::PP::Param.new(index))
    end
  end

  def emit(s : String)
    @body_io << s << '\n'
  end

  def build
    attrs = ""
    is_static = false
    @func_def.attrs.each do |attr|
      case attr
      when Mod::FuncDef::Attr::Noinline
        attrs += "__attribute__((noinline)) "
      when Mod::FuncDef::Attr::Private
        is_static = true
      end
    end
    unless builder.backend.common_options.final
      unless attrs.includes?("noinline")
        attrs += "__attribute__((noinline)) "
      end
    end
    emit("#{attrs}#{builder.func_head_str(@func_def.name, @func_def.type_fn, is_static)} {")

    v = new_visitor
    v.visit

    @alloca_bb.as(BB).copy_data(body_io, false)

    v.bb.as(BB).emit "goto ret;"

    @body_bb.as(BB).copy_data(body_io, false)
    @blocks.each &.copy_data(body_io, true)

    emit("")
    emit("ret:;")

    if @func_def.have_ret?
      emit("  return __myc_result;")
    else
      emit("  return;")
    end

    emit("}")
  end

  def register_block(bb : BB)
    @blocks << bb
  end
end
