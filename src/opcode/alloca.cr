# ALLOCA - Dynamic Stack Allocation
#
# Allocates memory on the stack dynamically. The number of elements
# is popped from the stack (must be integer), and a pointer to the
# allocated memory is pushed.
#
# Used for variable-length arrays (VLA). For variables use LOCAL.
#
# The allocated memory is automatically freed when the current function returns.
#
# STACK: [count:i64] - [ptr<T>]
#
#   PUSH 10             ; number of elements
#   ALLOCA :i32         ; allocate int[10] on stack
#   LOCAL :arr :ptr<i32>
#   STORE               ; arr = pointer to allocated memory
#
class Myc::Opcode::Alloca < Myc::Opcode
  getter type : Type

  def initialize(@type)
  end
end
