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
        emit("PUSH 1")
      else
        emit("PUSH 0")
      end
    when "__builtin_huge_val", "__builtin_inf", "__builtin_infl"
      emit("PUSH +inf")
    when "__builtin_huge_valf", "__builtin_inff"
      emit("PUSH +inf :f32")
    when "__builtin_fabs", "__builtin_fabsf", "__builtin_fabsl"
      generate_expr(args[0])
      emit("UNARY :abs")
    when "__builtin_nan"
      emit("PUSH +nan")
    when "__builtin_nanf"
      emit("PUSH +nan :f32")
    when "__builtin_isnan", "__builtin_isnanf"
      generate_expr(args[0])
      emit("STACK :dup")
      emit("BINARY :not_eq")
    when "__builtin_isinf_sign"
      case type = args[0].type
      when Type::FloatType
        case type.bytes_count
        when 8
          unless @generated_isinf_sign_64
            @generated_isinf_sign_64 = true
            isinf_sign(64)
          end
          generate_expr(args[0])
          emit("CALL :__myc_builtin_isinf_sign_64")
        when 4
          unless @generated_isinf_sign_32
            @generated_isinf_sign_32 = true
            isinf_sign(32)
          end
          generate_expr(args[0])
          emit("CALL :__myc_builtin_isinf_sign_32")
        else
          raise error("unexpected type", args[0])
        end
      else
        raise error("unexpected type", args[0])
      end
    when "__builtin_isfinite"
      case type = args[0].type
      when Type::FloatType
        case type.bytes_count
        when 8
          unless @generated_isfinite_64
            @generated_isfinite_64 = true
            isfinite(64)
          end
          generate_expr(args[0])
          emit("CALL :__myc_builtin_isfinite_64")
        when 4
          unless @generated_isfinite_32
            @generated_isfinite_32 = true
            isfinite(32)
          end
          generate_expr(args[0])
          emit("CALL :__myc_builtin_isfinite_32")
        else
          raise error("unexpected type", args[0])
        end
      else
        raise error("unexpected type", args[0])
      end
    when "__builtin_signbit"
      case type = args[0].type
      when Type::FloatType
        case type.bytes_count
        when 8
          unless @generated_signbit_64
            @generated_signbit_64 = true
            signbit(64)
          end
          generate_expr(args[0])
          emit("CALL :__myc_builtin_signbit_64")
        when 4
          unless @generated_signbit_32
            @generated_signbit_32 = true
            signbit(32)
          end
          generate_expr(args[0])
          emit("CALL :__myc_builtin_signbit_32")
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

  private def float_to_int(tmp_name : String, slot : String, size : Int32)
    <<-S
    LOCAL "#{tmp_name}" :f#{size}
    STORE
    LOCAL "#{tmp_name}"
    ADDR
    AS :ptr<u#{size}>
    DEREF
    SLOT #{slot}
    S
  end

  private def isinf_sign(size : Int32)
    emit2 <<-S
      FUNC :__myc_builtin_isinf_sign_#{size}
      ARGS TYPE :f#{size}
      RETURN TYPE :i32
      BODY
        PARAM 0
        #{float_to_int("tmp", "slot", size)}

        PUSH #{size == 64 ? "0x7FF" : "0xFF"} :u#{size}
        PUSH #{size == 64 ? 52 : 23} :u#{size}
        SLOT "slot"
        BINARY :shr
        BINARY :and
        SLOT :slot_exp

        PUSH 1 :u#{size}
        PUSH #{size == 64 ? 63 : 31} :u#{size}
        SLOT :slot
        BINARY :shr
        BINARY :and
        SLOT :slot_sign

        PUSH #{size == 64 ? "0x7FF" : "0xFF"} :u#{size}
        SLOT :slot_exp
        BINARY :eq

        PUSH 0 :u#{size}
        PUSH #{size == 64 ? "0x000FFFFFFFFFFFFF" : "0x007FFFFF"} :u#{size}
        SLOT :slot
        BINARY :and
        BINARY :eq

        BINARY :and
        IF
          THEN
            PUSH 1
            PUSH -1
            SLOT :slot_sign
            PUSH 0 :u#{size}
            BINARY :not_eq
            SELECT
            RET
        ENDIF

        PUSH 0
        RET
      ENDFUNC
    S
  end

  private def isfinite(size : Int32)
    emit2 <<-S
      FUNC :__myc_builtin_isfinite_#{size}
      ARGS TYPE :f#{size}
      RETURN TYPE :i32
      BODY
        PARAM 0
        #{float_to_int("tmp", "slot", size)}

        PUSH #{size == 64 ? "0x7FF" : "0xFF"} :u#{size}
        PUSH #{size == 64 ? 52 : 23} :u#{size}
        SLOT "slot"
        BINARY :shr
        BINARY :and
        AS :u#{size}

        PUSH #{size == 64 ? "0x7FF" : "0xFF"} :u#{size}
        BINARY :not_eq
        AS :i32
        RET
      ENDFUNC
    S
  end

  private def signbit(size : Int32)
    emit2 <<-S
      FUNC :__myc_builtin_signbit_#{size}
      ARGS TYPE :f#{size}
      RETURN TYPE :i32
      BODY
        PARAM 0
        #{float_to_int("tmp", "slot", size)}

        PUSH 1 :u#{size}
        PUSH #{size == 64 ? 63 : 31} :u#{size}
        SLOT "slot"
        BINARY :shr
        BINARY :and
        AS :i32
        RET
      ENDFUNC
    S
  end

  private def emit2(str : String)
    @additional_io << "  " * @indent << str << '\n'
  end
end
