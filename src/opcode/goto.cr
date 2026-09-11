# GOTO - Unconditional Jump
#
# *** NOT RECOMMENDED FOR DIRECT USE ***
# Prefer high-level constructs (IF, LOOP, SWITCH).
# GOTO/LABEL exist for code like fallthrought C-like switch
# and internal inlining only.
#
# Jumps to a label within the same function.
# Must target a LABEL inside the current function.
#
# --- Direct goto ---
# Single target, does not touch the stack.
# STACK: [] - []
#
#   GOTO :cleanup
#   ; ...
#   LABEL :cleanup
#   RET
#
# --- Indirect goto (computed goto) ---
# Two or more targets -> indirect form.
# The address is taken from the stack (type `:indirect`,
# produced by ADDR :label). Additional labels after the
# first are possible targets (used by backends that need
# an explicit list of destinations).
# STACK: [indirect] - []
#
#   ADDR :jmp1         ; push address of label jmp1 (type :indirect)
#   LOCAL :ptr :indirect
#   STORE
#   ; ...
#   LOCAL :ptr
#   GOTO :jmp1 :jmp2   ; jump via pointer, targets = {jmp1, jmp2}
#   ; ...
#   LABEL :jmp1
#   PUSH "in jmp1"
#   INSPECT
#   GOTO :end
#   LABEL :jmp2
#   PUSH "in jmp2"
#   INSPECT
#   LABEL :end
#
class Myc::Opcode::Goto < Myc::Opcode
  getter labels : Array(String)

  def initialize(@labels)
  end
end
