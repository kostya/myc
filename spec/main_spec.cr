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
#   numbers used to set mode: 0 - debug, 1 - default, 2 - final
#   'qbe1,qbe2' - means qbe default and qbe final
#   'llvm' - llvm in all modes
#   'qbe0,llvm1' - qbe in debug, llvm in default mode

Spec.before_suite { Examples.new.run }
