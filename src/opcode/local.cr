# LOCAL - Local Variable Access
#
# Pushes a local variable (always l-value). Create if not exists.
# Type required on first use, optional after. Must match if given.
#
# STACK: [] - [ptr<T>]
#
#   PUSH 42
#   LOCAL :x :i32          ; first use, type i32
#   STORE                  ; x = 42
#
#   LOCAL :x               ; reuse, type already known
#   INSPECT                ; 42
#
class Myc::Opcode::Local < Myc::Opcode
  getter name : String
  getter type : Type?

  def initialize(@name, @type = nil)
  end
end
