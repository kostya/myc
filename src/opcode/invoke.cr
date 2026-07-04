# INVOKE - Call Function Pointer
#
# Pops function pointer and arguments from stack, calls the function.
# First pushed = last argument, last pushed = function pointer.
# Pushes return value if function returns non-void.
#
# STACK: [argN, ..., arg0, fn_ptr] - [retval?]
#
#   ; Direct call (known function)
#   PUSH 20
#   PUSH 10
#   ADDR :add            ; "fn<i32, i32, i32>" = (i32,i32) -> i32
#   INVOKE               ; add(10, 20)
#
#   ; Through variable
#   PUSH 20
#   PUSH 10
#   LOCAL :fp "fn<i32, i32, i32>"
#   INVOKE               ; fp(10, 20)
#
#   ; Void function
#   PUSH "hello"
#   ADDR :log            ; "fn<ptr<u8>, void>"
#   INVOKE               ; log("hello")
#
class Myc::Opcode::Invoke < Myc::Opcode
  getter vaargs_count : Int32

  def initialize(@vaargs_count = 0)
  end
end
