# INVOKE - Call Function Pointer
#
# Pops function pointer and arguments from stack, calls the function.
# First pushed = last argument, last pushed = function pointer.
# Pushes return value if function returns non void.
# Supports vaargs (optional).
#
# STACK: [fn_ptr, arg0, ..., argN] - [retval?]
#
#   FUNC :printf ARGS TYPE :ptr<u8> RETURN TYPE :i32 ATTRIBUTES ATTR :vaarg ENDFUNC
#
#   ADDR :printf
#   LOCAL :f "fn<ptr<u8>, ..., i32>"
#   STORE
#
#   PUSH 1
#   PUSH "hello %d\n"
#   LOCAL :f
#   INVOKE 1
#
class Myc::Opcode::Invoke < Myc::Opcode
  getter vaargs_count : Int32

  def initialize(@vaargs_count = 0)
  end
end
