require "./spec_helper"

# FILTER=mycc,ir - filter by path
# BACKEND=LLVM,QBE - filter by backend LLVM0 - debug llvm, LLVM1 - final llvm, LLVM - both LLVM

Spec.before_suite do
  e = Examples.new
  e.run
end
