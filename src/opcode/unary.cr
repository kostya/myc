# UNARY - Unary Operation
#
# Pops one value, performs operation, pushes result.
#
# STACK: [value] -> [result]
#
# Operations:
#   lnot    - Logical NOT (1 -> 0, 0 -> 1)
#   bnot    - Bitwise NOT (~1 -> -2)
#   neg     - Negation (-42 -> 42)
#   abs     - Absolute value (-3.14 -> 3.14)
#   clz     - Count leading zeros (Int: 1 -> 31)
#   ctz     - Count trailing zeros (Int: 8 -> 3)
#   popcnt  - Population count (Int: 7 -> 3)
#   ceil    - Round up (Float: 3.14 -> 4.0)
#   floor   - Round down (Float: 3.14 -> 3.0)
#   trunc   - Truncate fractional part (Float: -3.14 -> -3.0)
#   nearest - Round to nearest (Float: 3.6 -> 4.0)
#   sqrt    - Square root (Float: 16.0 -> 4.0)
#
class Myc::Opcode::Unary < Myc::Opcode
  enum Op
    Lnot
    Bnot
    Neg
    Clz
    Ctz
    Popcnt
    Abs
    Ceil
    Floor
    Trunc
    Nearest
    Sqrt
  end

  getter op : Op

  def initialize(@op)
  end
end
