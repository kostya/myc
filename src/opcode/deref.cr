# DEREF - Pointer Dereference
#
# Converts a pointer to an l-value for reading or writing.
#
# STACK: [ptr<T>] - [T (l-value)]
#
#   LOCAL :ptr :ptr<i32>
#   DEREF                ; l-value for *ptr
#   LOCAL :x :i32
#   STORE                ; x = *ptr
#
#   PUSH 42
#   LOCAL :ptr :ptr<i32>
#   DEREF                ; l-value for *ptr
#   STORE                ; *ptr = 42
#
class Myc::Opcode::Deref < Myc::Opcode
end
