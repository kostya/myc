# SLOT - Named Stack Slot (Internal)
#
# Creates or reads a named temporary slot on the stack.
# First use creates the slot and pops a value from stack into it.
# Subsequent uses push the slot's value onto the stack.
#
# NOTE: This opcode is intended for internal compiler use only
# (primarily for function inlining). It is not expected to be
# used in manually written IR. For regular temporary values,
# use LOCAL/STORE instead.
#
# SCOPING: A SLOT cannot escape its defining scope. If a SLOT is
# created inside an IF/THEN or ELSE branch, it cannot be used
# outside that branch.
#
# STACK: [value] -> [] (first use, create)
# STACK: [] -> [value] (subsequent use, read)
#
#   ; First use: create slot, store 42
#   PUSH 42
#   SLOT :tmp        ; tmp = 42 (create)
#
#   ; Subsequent use: read slot
#   SLOT :tmp        ; push 42 (read)
#   PUSH 10
#   BINARY :add      ; 10 + 42 = 52
#   SLOT :tmp2       ; tmp2 = 52 (new slot)
#
#   ; INVALID: SLOT used outside its defining branch
#   IF
#     THEN
#       PUSH 1
#       SLOT :x      ; x created in THEN branch
#     ELSE
#       PUSH 2
#       SLOT :y      ; y created in ELSE branch
#   ENDIF
#   SLOT :x          ; ERROR: x not in scope here
class Myc::Opcode::Slot < Myc::Opcode
  getter name : String

  def initialize(@name)
  end
end
