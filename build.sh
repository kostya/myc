crystal build ./src/cli/llvm.cr --release -o myc-llvm
# crystal build ./src/cli/test.cr --release -o myc-test
crystal build ./src/cli/c.cr --release -o myc-c
crystal build ./src/cli/qbe.cr --release -o myc-qbe
crystal build ./src/cli/gm.cr --release -o myc-gm
shards
crystal build ./src/cli/mycc.cr --release -o mycc
