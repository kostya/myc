# TO - Safe Type Conversion (Promotion/Coercion)
#
# Safely converts top of stack to the given type.
# Only allows widening/promotion conversions, never truncation.
# Used automatically by BINARY, CALL, INVOKE, STORE, RET operations.
# For data loss coercions use AS instead.
#
# Allowed conversions:
#   Int   -> Larger Int   (u8 -> i32, i32 -> i64)
#   Int   -> Float        (i32 -> f64)
#   Float -> Larger Float (f32 -> f64)
#   ptr<T> -> ptr<void>   (type erasure, always safe)
#
# STACK: [value] - [value as TYPE]
#
#   PUSH 5 :i32
#   TO :i64        ; 5:i64 (safe widening)
#
#   PUSH 3 :u8
#   TO :f64        ; 3.0:f64 (safe int->float)
#
#   LOCAL :p :ptr<i32>
#   TO :ptr<void>  ; safe type erasure
#
# Automatic usage:
#   PUSH 5 :i32
#   PUSH 3.14 :f64
#   BINARY :add    ; auto TO :f64 for left operand
#
#   PUSH 42 :u8
#   CALL :malloc   ; auto TO :i64 before call
#
class Myc::Opcode::To < Myc::Opcode
  getter type : Type

  def initialize(@type)
  end
end
