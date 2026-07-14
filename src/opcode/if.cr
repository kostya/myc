# IF - Conditional Branch
#
# Pops a Bool condition. Executes THEN if true, ELSE if false.
# Both branches must leave stack balanced.
#
# To return a value from a branch, store it in a LOCAL variable.
# Branches cannot leave values on the stack.
#
# STACK: [Bool] - []
#
#   PUSH 5
#   PUSH 10
#   BINARY :less
#   IF
#     THEN
#       PUSH "yes"
#       LOCAL :result :ptr<u8>
#       STORE
#     ELSE
#       PUSH "no"
#       LOCAL :result
#       STORE
#   ENDIF
#   LOCAL :result   ; load result back
#   INSPECT
#
class Myc::Opcode::If < Myc::Opcode
  property then_seq : Seq
  property else_seq : Seq

  def initialize(@then_seq, @else_seq)
  end
end
