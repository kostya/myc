# BINARY — Binary Operation
#
# Pops two values, performs the operation, pushes result.
# First popped = RIGHT operand, second popped = LEFT operand.
# All types must match exactly — no implicit conversions.
#
# STACK: [right, left] -> [result]
#
#   PUSH 10      ; right
#   PUSH 5       ; left
#   BINARY :less ; 5 < 10 -> true
#
#   PUSH 3       ; right
#   PUSH 2       ; left
#   BINARY :sub  ; 2 - 3 -> -1
#
# Operations:
#   Arithmetic (Int/Float): add, sub, mul, div, rem
#   Bitwise (Int/Bool):     and, or, xor, shl, shr, sar
#   Comparison (-> Bool):    eq, not_eq, less, less_eq, more, more_eq
#
# Bool is a single-bit Int. Bitwise ops on Bool give logical results.
# For logical ops on Int, convert to Bool first: AS :bool or != 0.
#
# Pointer arithmetic:
#   When left is ptr<T> and right is Int, :add and :sub perform
#   pointer arithmetic (Int × sizeof(T)).
#
#   PUSH 3 :i32
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
