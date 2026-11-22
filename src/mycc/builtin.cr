class Myc::Mycc::CodeGenerator
  @generated_isinf_sign_64 = false
  @generated_isinf_sign_32 = false
  @generated_isfinite_64 = false
  @generated_isfinite_32 = false
  @generated_signbit_64 = false
  @generated_signbit_32 = false

  def generate_builtin(name : String, type : Type, args : Array(TypedAST::Node)) : Bool
    case name
    when "__builtin_expect"
      generate_expr(args[0])
    when "__builtin_constant_p"
      case args[0]
      when TypedAST::IntLiteral, TypedAST::FloatLiteral
        emit_op(push(1))
      else
        emit_op(push(0))
      end
    when "__builtin_huge_val", "__builtin_inf", "__builtin_infl"
      emit_op(push(Float64::INFINITY))
    when "__builtin_huge_valf", "__builtin_inff"
      emit_op(push(Float64::INFINITY, typer.f32))
    when "__builtin_fabs", "__builtin_fabsf", "__builtin_fabsl"
      generate_expr(args[0])
      emit_op(Opcode::Unary.new(:abs))
    when "__builtin_nan"
      emit_op(push(Float64::NAN))
    when "__builtin_nanf"
      emit_op(push(Float64::NAN, typer.f32))
    when "__builtin_isnan", "__builtin_isnanf"
      generate_expr(args[0])
      emit_op(Opcode::Stack.new(:dup))
      emit_op(Opcode::Binary.new(:not_eq))
      emit_op(Opcode::As.new(typer.i32))
    when "__builtin_isinf_sign"
      case t = args[0].type
      when Type::FloatType
        case t.bytes_count
        when 8
          unless @generated_isinf_sign_64
            @generated_isinf_sign_64 = true
            isinf_sign(64)
          end
          generate_expr(args[0])
          emit_op(Opcode::Call.new("__myc_builtin_isinf_sign_64", 0))
        when 4
          unless @generated_isinf_sign_32
            @generated_isinf_sign_32 = true
            isinf_sign(32)
          end
          generate_expr(args[0])
          emit_op(Opcode::Call.new("__myc_builtin_isinf_sign_32", 0))
        else
          raise error("unexpected type", args[0])
        end
      else
        raise error("unexpected type", args[0])
      end
    when "__builtin_isfinite"
      case t = args[0].type
      when Type::FloatType
        case t.bytes_count
        when 8
          unless @generated_isfinite_64
            @generated_isfinite_64 = true
            isfinite(64)
          end
          generate_expr(args[0])
          emit_op(Opcode::Call.new("__myc_builtin_isfinite_64", 0))
        when 4
          unless @generated_isfinite_32
            @generated_isfinite_32 = true
            isfinite(32)
          end
          generate_expr(args[0])
          emit_op(Opcode::Call.new("__myc_builtin_isfinite_32", 0))
        else
          raise error("unexpected type", args[0])
        end
      else
        raise error("unexpected type", args[0])
      end
    when "__builtin_signbit"
      case t = args[0].type
      when Type::FloatType
        case t.bytes_count
        when 8
          unless @generated_signbit_64
            @generated_signbit_64 = true
            signbit(64)
          end
          generate_expr(args[0])
          emit_op(Opcode::Call.new("__myc_builtin_signbit_64", 0))
        when 4
          unless @generated_signbit_32
            @generated_signbit_32 = true
            signbit(32)
          end
          generate_expr(args[0])
          emit_op(Opcode::Call.new("__myc_builtin_signbit_32", 0))
        else
          raise error("unexpected type", args[0])
        end
      else
        raise error("unexpected type", args[0])
      end
    when "__builtin_va_end"
      generate_expr(args[0])
      emit_op(Opcode::Va.new(:end, nil))
    when "__builtin_va_start"
      generate_expr(args[1])
      generate_expr(args[0])
      emit_op(Opcode::Va.new(:start, nil))
    when "__builtin_va_copy"
      generate_expr(args[1])
      generate_expr(args[0])
      emit_op(Opcode::Store.new)
    when "__builtin_alloca"
      generate_expr(args[0])
      emit_op(Opcode::Alloca.new(typer.u8))
    when "__builtin_isinf", "__builtin_isinff", "__builtin_isinfl"
      case t = args[0].type
      when Type::FloatType
        case t.bytes_count
        when 8
          unless @generated_isinf_sign_64
            @generated_isinf_sign_64 = true
            isinf_sign(64)
          end
          generate_expr(args[0])
          emit_op(Opcode::Call.new("__myc_builtin_isinf_sign_64", 0))
          emit_op(push(0))
          emit_op(Opcode::Binary.new(:not_eq))
          emit_op(Opcode::As.new(typer.i32))
        when 4
          unless @generated_isinf_sign_32
            @generated_isinf_sign_32 = true
            isinf_sign(32)
          end
          generate_expr(args[0])
          emit_op(Opcode::Call.new("__myc_builtin_isinf_sign_32", 0))
          emit_op(push(0))
          emit_op(Opcode::Binary.new(:not_eq))
          emit_op(Opcode::As.new(typer.i32))
        else
          raise error("unexpected type", args[0])
        end
      else
        raise error("unexpected type", args[0])
      end
    else
      return false
    end

    true
  end

  private def emit_float_to_int(tmp_name : String, slot : String, size : Int32)
    float_ty = size == 64 ? typer.f64 : typer.f32
    uint_ty = size == 64 ? typer.u64 : typer.u32

    emit_op(Opcode::Local.new(tmp_name, float_ty))
    emit_op(Opcode::Store.new)
    emit_op(Opcode::Local.new(tmp_name))
    emit_op(Opcode::Addr.new)
    emit_op(Opcode::As.new(typer.to_ptr(uint_ty)))
    emit_op(Opcode::Deref.new)
    emit_op(Opcode::Slot.new(slot))
  end

  private def isinf_sign(size : Int32)
    float_ty = size == 64 ? typer.f64 : typer.f32
    uint_ty = size == 64 ? typer.u64 : typer.u32

    exp_mask = size == 64 ? 0x7FF_i64 : 0xFF_i64
    exp_shift = size == 64 ? 52_i64 : 23_i64
    sign_shift = size == 64 ? 63_i64 : 31_i64
    frac_mask = size == 64 ? 0x000F_FFFF_FFFF_FFFF_i64 : 0x007F_FFFF_i64

    build_func_def("__myc_builtin_isinf_sign_#{size}", Type::Fn.new(Location.new("", 0), [float_ty], typer.i32)) do
      emit_op(Opcode::Param.new(0))
      emit_float_to_int("tmp", "slot", size)

      emit_op(push(exp_mask, uint_ty))
      emit_op(push(exp_shift, uint_ty))
      emit_op(Opcode::Slot.new("slot"))
      emit_op(Opcode::Binary.new(:shr))
      emit_op(Opcode::Binary.new(:and))
      emit_op(Opcode::Slot.new("slot_exp"))

      emit_op(push(1_i64, uint_ty))
      emit_op(push(sign_shift, uint_ty))
      emit_op(Opcode::Slot.new("slot"))
      emit_op(Opcode::Binary.new(:shr))
      emit_op(Opcode::Binary.new(:and))
      emit_op(Opcode::Slot.new("slot_sign"))

      emit_op(push(exp_mask, uint_ty))
      emit_op(Opcode::Slot.new("slot_exp"))
      emit_op(Opcode::Binary.new(:eq))

      emit_op(push(0_i64, uint_ty))
      emit_op(push(frac_mask, uint_ty))
      emit_op(Opcode::Slot.new("slot"))
      emit_op(Opcode::Binary.new(:and))
      emit_op(Opcode::Binary.new(:eq))

      emit_op(Opcode::Binary.new(:and))

      then_seq = build_seq do
        emit_op(push(1))
        emit_op(push(-1))
        emit_op(Opcode::Slot.new("slot_sign"))
        emit_op(push(0_i64, uint_ty))
        emit_op(Opcode::Binary.new(:not_eq))
        emit_op(Opcode::Select.new)
        emit_op(Opcode::Ret.new)
      end

      emit_op(Opcode::If.new(then_seq, Opcode::Seq.new))

      emit_op(push(0))
      emit_op(Opcode::Ret.new)
    end
  end

  private def isfinite(size : Int32)
    float_ty = size == 64 ? typer.f64 : typer.f32
    uint_ty = size == 64 ? typer.u64 : typer.u32

    exp_mask = size == 64 ? 0x7FF_i64 : 0xFF_i64
    exp_shift = size == 64 ? 52_i64 : 23_i64

    build_func_def("__myc_builtin_isfinite_#{size}", Type::Fn.new(Location.new("", 0), [float_ty], typer.i32)) do
      emit_op(Opcode::Param.new(0))
      emit_float_to_int("tmp", "slot", size)

      emit_op(push(exp_mask, uint_ty))
      emit_op(push(exp_shift, uint_ty))
      emit_op(Opcode::Slot.new("slot"))
      emit_op(Opcode::Binary.new(:shr))
      emit_op(Opcode::Binary.new(:and))
      emit_op(Opcode::As.new(uint_ty))

      emit_op(push(exp_mask, uint_ty))
      emit_op(Opcode::Binary.new(:not_eq))
      emit_op(Opcode::As.new(typer.i32))
      emit_op(Opcode::Ret.new)
    end
  end

  private def signbit(size : Int32)
    float_ty = size == 64 ? typer.f64 : typer.f32
    uint_ty = size == 64 ? typer.u64 : typer.u32
    sign_shift = size == 64 ? 63_i64 : 31_i64

    build_func_def("__myc_builtin_signbit_#{size}", Type::Fn.new(Location.new("", 0), [float_ty], typer.i32)) do
      emit_op(Opcode::Param.new(0))
      emit_float_to_int("tmp", "slot", size)

      emit_op(push(1_i64, uint_ty))
      emit_op(push(sign_shift, uint_ty))
      emit_op(Opcode::Slot.new("slot"))
      emit_op(Opcode::Binary.new(:shr))
      emit_op(Opcode::Binary.new(:and))
      emit_op(Opcode::As.new(typer.i32))
      emit_op(Opcode::Ret.new)
    end
  end
end
