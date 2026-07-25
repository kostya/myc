require "./spec_helper"

# run tests from examples/ dir
#
# Run all:
# crystal spec spec/main_spec.cr
#
# you can set BACKEND and FILTER to reduce spec time. FILTER - find matches test filename.
#
# example:
# FILTER=/mycc/ BACKEND=qbe0 crystal spec spec/main_spec.cr
#
# BACKEND is a list separated by comma, variants: qbe,c,llvm:
#   'qbe0,qbe1' - means qbe default and qbe final
#   '0' - means all backends default mode, '1' all in final mode
#   'llvm' - llvm in both modes
#   'qbe0,llvm1' - qbe in default, llvm in final mode

Spec.before_suite { Examples.new.run }
