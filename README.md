# myc - MyCompiler

**A small IR for building programming languages.**

### What is it?

* Simple DSL over LLVM/QBE.
* Your language AST -> mycIR -> [LLVM / QBE / C] -> binary.
* ~30 stack-based opcodes.
* Whole IR spec fits in 30 minutes of reading. 
* Compiles to native code via LLVM, QBE, or C. 
* Fast compilation, "zero" overhead (I hope). 
* ~8000 lines in Crystal.
* Includes mycc: a C11-like compiler built on myc (3000 lines).

### Why?

* I was writing my own language and got tired of fighting with LLVM IR. SSA and basic blocks - X(.
* Usually when you write your own language, you first build a parser and generate an AST. Then comes the hell stage: translating your AST into LLVM or another backend. Myc takes on all that complexity.
* LLVM is complex. 
* Myc is simple and fun.
* Stack-based opcodes are easy to emit from AST with a simple one-pass tree walk.
* You're not locked into one backend. LLVM for speed, QBE for fast compiles, C for anywhere.

### Current status

* Alpha, but already powerful.
* All 3 backends work smoothly.
* 4400 tests pass.
* Mycc compiles [LangArena](https://github.com/kostya/LangArena) benchmark - 50 tests, 9,000 lines of production-like C (json, base64, neural net, compression, maze A*, and more) and 20/34 files of Lua. 
* Two modes: default (fast, Go-like) and final (slow compile, ~5-15% faster runtime).

## How it looks like?

```myc
FUNC :main
  BODY
    PUSH :MYC_BACKEND
    PUSH :MYC_FLAGS
    PUSH "Hello from (myc)MyCompiler (flags = %s, backend = %s)!\n"
    PRINTF 2
ENDFUNC
```

## Benchmark: LangArena - Pure IR Compilation, Myc vs Clang

![plot](https://github.com/kostya/myc-benchmarks/blob/master/plot1.png?raw=true)

This scatter plot shows the tradeoff between compile time and runtime. The ideal is the bottom-left corner: fast compiles, fast runtime. This is the Pareto frontier - you can't improve one without sacrificing the other. Myc-qbe(default) and myc-llvm(default) occupy a spot that even Go would respect. Measured on pure IR files - no C parsing overhead, just optimization and code generation for both MycIR and LLVM-LL. [Link to benchmark and reproduce steps](https://github.com/kostya/myc-benchmarks#benchmark-1-langarena-single-ir-file-myc-vs-clang).

## mycIR

All opcodes [self documented](https://github.com/kostya/myc/tree/master/src/opcode). Also see [examples](https://github.com/kostya/myc/tree/master/examples).

* 24 main opcodes: PUSH, LOCAL, STORE, CALL, PARAM, BINARY, UNARY, FIELD, DEREF, ADDR, AS, SELECT, MALLOC, CREATE, INSPECT, PRINTF, STACK, SIZEOF, TO, INVOKE, LABEL, GOTO, ALLOCA, SLOT.
* 6 Control flow: IF/THEN/ELSE, LOOP/INIT/COND/BODY/STEP, SWITCH/CASE, BREAK, NEXT, RET.
* Types: STRUCT, ENUM/VARIANT, FLAT + void, bool, i8..i64, u8..u64, f32, f64, ptr<T>.

## Install

Requires [Crystal](https://crystal-lang.org) to compile the myc compiler.

### Quick Start (compile and run first program).

```sh
echo 'FUNC main BODY PUSH "Hello myc\n" PRINTF 0 ENDFUNC' | crystal src/cli/llvm.cr r
```

### Compile

```sh
# compile Myc IR C backend
crystal build src/cli/c.cr --release -o myc-c

# compile Myc IR LLVM backend
# requires LLVM >= 15.0, install it system wide or provide LLVM_CONFIG env variable
crystal build src/cli/llvm.cr --release -o myc-llvm 

# compile Myc IR Qbe backend
# uses `qbe` from PATH, or the one given by the QBE env variable,
# otherwise build it locally as shown below
git clone https://github.com/kostya/qbe.git plugins/qbe
cd plugins/qbe; make; cd -
crystal build src/cli/qbe.cr --release -o myc-qbe
```

## Examples:

```sh
# run
./myc-llvm r examples/ir/mandel.myc

# compile and run
./myc-llvm c examples/ir/bf.myc && ./bf

# show llvm IR
./myc-llvm examples/ir/loop.myc d

# show qbe IR
./myc-qbe examples/ir/loop.myc d

# explain myc IR
./myc-llvm examples/ir/bf.myc e

# example brainfuck compiler with Myc
cd benchmark/brainfuck-compiler
python3 bf2myc.py mandel.bf | ../../myc-llvm run
cd ../../
```

# mycc - an alternative C compiler.

As a proof of concept, I built mycc: a compiler for a subset of C (roughly C11) on top of myc. This proves that creating languages is easy. For parsing, I used libclang - it adds overhead, but it's the simplest solution for a POC. It is only 3000 lines of code and already compiles complex and production-like C, like: LangArena and part of Lua.

## How it works:

`C source -> SyntaxTree(libclang/clang.cr) -> TypedAST(mycc) -> IR(myc) -> [LLVM/QBE/C] -> binary`

The most challenging part was `SyntaxTree -> TypedAST`. In the file [ast_builder.cr](https://github.com/kostya/myc/blob/master/src/mycc/ast_builder.cr) which contains 1700 lines of code. libclang returns a non-normalized Tree with many edge cases that need to be transformed into a consistent form. Additionally, C has a ton of implicit behavior.

The `TypedAST(mycc) -> IR(myc)` stage as expected, is one of the simplest ([codegen.cr](https://github.com/kostya/myc/blob/master/src/mycc/codegen.cr), 700 lines) - a single-pass generation of stack-based IR directly from the AST.

### Difference from Clang:

clang: `C -> Parse(libclang) -> Clang CodeGen -> LLVM -> binary`

mycc: `C -> Parse(libclang) -> mycc CodeGen -> IR(myc) -> [LLVM/QBE/C] -> binary`

### Limitations: 

Rare features are not implemented: va_list, long double, atomic, complex numbers, longjmp, bitfields, asm. I wouldn't try building Linux or sqlite with it. It has only been tested on arm64 and linux64.

## mycc: build compiler.

Requires LLVM/libclang >= 20.

```sh
# sudo apt install llvm-20 libclang-20-dev
shards install
crystal build src/cli/mycc.cr --release -o ./mycc
```

## mycc: usage example.
```
# compile file
./mycc c examples/mycc/sieve.c

# compile file with --backend option
./mycc c --backend llvm examples/mycc/sieve.c
./mycc c --backend qbe examples/mycc/sieve.c
./mycc c --backend c examples/mycc/sieve.c

# show myc dump
./mycc examples/mycc/sieve.c d

# show llvm ir dump
./mycc examples/mycc/sieve.c d | ./myc-llvm d

# show qbe dump
./mycc examples/mycc/sieve.c d | ./myc-qbe d

# include paths example
MYCC_INCLUDE='/opt/homebrew/include,/usr/local/include' ./mycc examples/mycc/sieve.c c

# Build object file for custom linking
./mycc o examples/mycc/sieve.c sieve.o
clang sieve.o -lm -o ./sieve
```

## More benchmarks
[Here](https://github.com/kostya/myc-benchmarks)

## License

Licensed under the Apache License, Version 2.0.

## Thanks

- [Crystal language](https://crystal-lang.org)
- [QBE](https://c9x.me/compile/)
- [LLVM](https://llvm.org/)
- [clang.cr](https://github.com/crystal-lang/clang.cr)
