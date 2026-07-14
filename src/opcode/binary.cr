# BINARY — Binary Operation
#
# Pops two values, performs the operation, pushes result.
# First popped = left operand, second popped = right operand.
# All types must match exactly — but allowed TO coercion.
#
# STACK: [left, right] -> [result]
#
#   PUSH 10      ; right
#   PUSH 5       ; left
#   BINARY :less ; 5 < 10 -> true
#   INSPECT
#
#   PUSH 3       ; right
#   PUSH 2       ; left
#   BINARY :sub  ; 2 - 3 -> -1
#   INSPECT
#
# Operations:
#   Arithmetic (Int/Float): add, sub, mul, div, rem
#   Bitwise (Int/Bool):     and, or, xor, shl, shr, sar
#   Comparison (-> Bool):    eq, not_eq, less, less_eq, more, more_eq
#
# Pointer arithmetic:
#   When left is ptr<T> and right is Int, :add and :sub perform pointer arithmetic.
#
#   PUSH 3
#   LOCAL :arr :ptr<i32>
#   BINARY :add           ; arr + 3 * sizeof(i32)
#
class Myc::Opcode::Binary < Myc::Opcode
  enum Op
    Add
    Sub
    Mul
    Div
    Rem

    And
    Or
    Xor
    Shl
    Shr
    Sar

    Eq
    NotEq
    Less
    LessEq
    More
    MoreEq
  end

  getter op : Op

  def initialize(@op)
  end
end
