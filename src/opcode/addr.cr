# ADDR - Address Of Variable or Function
#
# Without argument: takes the address of a local variable (Alloca).
# With argument: creates a function pointer.
#
# STACK (variable): [Alloca] - [ptr<T>]
# STACK (function): [] - [fn<Args, Ret>]
#
#   ; Variable address
#   LOCAL :x :i32
#   ADDR                 ; ptr<i32>
#   CALL :increment      ; increment(&x)
#
#   ; Call through function pointer
#   PUSH 20
#   PUSH 10
#   ADDR :add            ; "fn<i32, i32, i64>" = (i32,i32) -> i64
#   INVOKE               ; add(10, 20)
#
class Myc::Opcode::Addr < Myc::Opcode
  getter func_name : String?

  def initialize(@func_name = nil)
  end
end
