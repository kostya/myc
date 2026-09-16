# VA - Variable Argument List Operations
#
# --- START ---
# Initializes a `valist`. The last fixed argument must be on the stack.
#
# STACK: [storage of type :valist, last_fixed_arg] -> []
#
#   PARAM 0            ; last fixed argument (e.g. n in sum(int n, ...))
#   LOCAL :a :valist
#   VA :start
#
# --- ARG ---
# Reads the next variadic argument of the given `type` and
# advances the `valist`. The `valist` is on the stack.
#
# STACK: [valist] -> [arg]
#
#   LOCAL :a
#   VA :arg :i32       ; read next int, push it
#
# --- END ---
# Releases resources associated with the `valist`.
# On most ABIs this is a no-op.
#
# STACK: [valist] -> []
#
#   LOCAL :a
#   VA :end
#
class Myc::Opcode::Va < Myc::Opcode
  enum Op
    Start
    Arg
    End
  end

  getter op : Op
  getter type : Type?

  def initialize(@op, @type)
  end
end