# myc - MyCompiler

**A small IR for building programming languages.**

### What is it?

* Simple DSL over LLVM/QBE.
* Your language AST -> mycIR -> [LLVM / QBE / C] -> binary.
* ~30 stack-based opcodes.
* Whole IR spec fits in 30 minutes of reading. 
* Compiles to native code via LLVM, QBE, or C. 
* Fast compilation, "zero" overhead (I hope). 
* ~7800 lines in Crystal.
* Includes mycc as POC: a C subset compiler using myc as backend and libclang for parsing.

### Why?

* I was writing my own language and got tired of fighting with LLVM IR. SSA and basic blocks - X(.
* Usually when you write your own language, you first build a parser and generate an AST. Then comes the hell stage: translating your AST into LLVM or another backend. Myc takes on all that complexity.
* LLVM is complex. 
* Myc is simple and fun.
* Stack-based opcodes are easy to emit from AST with a simple one-pass tree walk.
* You're not locked into one backend. LLVM for speed, QBE for fast compiles, C for anywhere.

### Current status

Alpha. But already powerful. All 3 backends work smoothly. 4300 tests pass. mycc can compile [LangArena](https://github.com/kostya/LangArena) benchmark (230kb non-trivial C code). I wasn't able to beat gcc and clang in both compile time and runtime speed at the same time. So instead, I'm focusing on two compromise modes: default(fast compilation with decent runtime performance (like golang)), and final(slow compilation with maximum performance, for when you need every last bit of speed (this mode adds ~5-15% performance)).


## Benchmark: 

Mandelbrot renderer from mandel.bf (by Erik Bosman). All IRs represent the same program. This shows whether Myc adds overhead over direct backend usage. Running on Ryzen3800+Linux in benchmark/brainfuck-compiler.

| IR | Compiler | IR size, Kb | Compile time | Run time |
|:---------:|:---------:|:---------:|:---------:|:---------:|
| llvm-ll | clang(-O3) | 1529 | 1535ms | 621ms |
| myc | myc-llvm(default) | 486 | **257ms** | 681ms |
| myc | myc-llvm(final) | 486 | 1550ms | 631ms |
| qbe-ssa | qbe + clang(as+linker) | 345 | 83ms + 64ms | 807ms |
| myc | myc-qbe(default) | 486 | 460ms | 832ms |
| c | clang(-O3) | 128 | 1581ms | 636ms |
| myc | myc-c(default) | 486 | 1511ms | 634ms |
| myc | myc-c(final) | 486 | 1807ms | 637ms |

Default mode: faster compilation, ~10% slower runtime vs Clang -O3. Final mode: matches Clang -O3.

## Install

Requires [Crystal](https://crystal-lang.org) to compile the myc compiler.

### Quick Start (compile and run first program).

```sh
echo 'FUNC main BODY PUSH "Hello myc\n" PRINTF 0 ENDFUNC' | crystal src/cli/llvm.cr r
```

### Build

```sh
git clone https://github.com/kostya/myc && cd myc

# compile Myc IR C backend
crystal build src/cli/c.cr --release -o myc-c

# compile Myc IR LLVM backend
# requires LLVM >= 15.0, install it system wide or provide LLVM_CONFIG env variable
crystal build src/cli/llvm.cr --release -o myc-llvm 

# compile Myc IR Qbe backend
git clone https://github.com/kostya/qbe.git plugins/qbe
cd plugins/qbe; make; cd -
crystal build src/cli/qbe.cr --release -o myc-qbe
```

## mycIR

All opcodes [self documented](https://github.com/kostya/myc/tree/master/src/opcode). Also see [examples](https://github.com/kostya/myc/tree/master/examples).

* 24 main opcodes: PUSH, LOCAL, STORE, CALL, PARAM, BINARY, UNARY, FIELD, DEREF, ADDR, AS, SELECT, MALLOC, CREATE, INSPECT, PRINTF, STACK, SIZEOF, TO, INVOKE, LABEL, GOTO, ALLOCA, SLOT.
* 6 Control flow: IF/THEN/ELSE, LOOP/INIT/COND/BODY/STEP, SWITCH/CASE, BREAK, NEXT, RET.
* Types: STRUCT, ENUM/VARIANT, FLAT + void, bool, i8..i64, u8..u64, f32, f64, ptr<T>.


## Examples:

### Brainfuck compiler with myc IR.

```sh
cd benchmark/brainfuck-compiler
python3 bf2myc.py mandel.bf | ../../myc-llvm run
```

## More examples.

```sh
./myc-llvm run examples/ir/mandel.myc
./myc-llvm run examples/ir/bf.myc
./myc-llvm run examples/ir/loop.myc
```

### Factorial in mycIR, examples/ir/fact.myc, translation

<details>
<summary>examples/ir/fact.myc</summary>

```myc
FUNC fact
  ARGS
    TYPE i32
  RETURN
    TYPE i32
  BODY
    PUSH 1
    PARAM 0
    BINARY less_eq
    IF
      THEN
        PUSH 1
        RET
    ENDIF
    PUSH 1
    PARAM 0
    BINARY sub
    CALL fact
    PARAM 0
    BINARY mul
    RET
ENDFUNC

FUNC main
  BODY
    PUSH 5
    CALL fact
    INSPECT
ENDFUNC
```
</details>

<details>
<summary>LLVM Backend `./myc-llvm dump examples/ir/fact.myc`</summary>

```
; ModuleID = 'fact'
source_filename = "fact"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-darwin23.3.0"

@str = private constant [15 x i8] c"fact(%d) = %d\0A\00"

define i32 @fact(i32 %0) {
alloca:
  %__myc_result = alloca i32, align 4
  br label %body

body:                                             ; preds = %alloca
  %1 = icmp sle i32 %0, 1
  br i1 %1, label %then, label %endif

ret:                                              ; preds = %endif, %then
  %2 = load i32, ptr %__myc_result, align 4
  ret i32 %2

then:                                             ; preds = %body
  store i32 1, ptr %__myc_result, align 4
  br label %ret

endif:                                            ; preds = %body
  %3 = sub i32 %0, 1
  %4 = call i32 @fact(i32 %3)
  %5 = mul i32 %0, %4
  store i32 %5, ptr %__myc_result, align 4
  br label %ret
}

define void @main() {
alloca:
  br label %body

body:                                             ; preds = %alloca
  %0 = call i32 @fact(i32 5)
  %1 = call i32 (ptr, ...) @printf(ptr @str, i32 5, i32 %0)
  br label %ret

ret:                                              ; preds = %body
  ret void
}

declare i32 @printf(ptr, ...)
```

</details>

<details>
<summary>QBE Backend `./myc-qbe dump examples/ir/fact.myc`</summary>

```
data $str_0 = { b "fact(%d) = %d\n", b 0 }
export function w $fact(w %arg0) {
@start
  %__myc_result =l alloc8 4
  jmp @body
@body
  %t1 =w cslew %arg0, 1
  jnz %t1, @then_1, @endif_2
@then_1
  storew 1, %__myc_result
  jmp @ret
@endif_2
  %t2 =w sub %arg0, 1
  %t3 =w call $fact(w %t2)
  %t4 =w mul %arg0, %t3
  storew %t4, %__myc_result
  jmp @ret
@ret
  %ret_val =w loadw %__myc_result
  ret %ret_val
}

export function  $main() {
@start
  jmp @body
@body
  %t1 =w call $fact(w 5)
  %t2 =w call $printf(l $str_0, ..., w 5, w %t1)
  jmp @ret
@ret
  ret
}
```

</details>

<details>
<summary>C Backend `./myc-c dump examples/ir/fact.myc`</summary>

```
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>

int32_t fact(int32_t arg0);
void main();
int32_t fact(int32_t arg0) {
  int32_t __myc_result;
  int t1 = arg0 <= 1;
  if (t1) goto then_1; else goto endif_2;

then_1:;
  __myc_result = 1;
  goto ret;

endif_2:;
  int32_t t2 = arg0 - 1;
  int32_t t3 = fact(t2);
  int32_t t4 = arg0 * t3;
  __myc_result = t4;
  goto ret;

ret:;
  return __myc_result;
}
void main() {
  int32_t t5 = fact(5);
  int32_t t6 = printf("fact(%d) = %d\n", 5, t5);
  goto ret;

ret:;
  return;
}
```

</details>

## Run tests

```
crystal spec
```

## Usage

<details>
<summary>Usage</summary>

```
Usage: ./myc-llvm COMMAND [OPTIONS] INPUT [INPUT]* [OUTPUT]

Commands:

  compile|c  ; compile multiple .myc files into executable binary
             ;   ./myc-llvm c file.myc out
             ;   cat file.myc | ./myc-llvm c out

  run|r      ; compile multiple .myc files and run the program
             ;   ./myc-llvm r file.myc
             ;   cat file.myc | ./myc-llvm r

  obj|o      ; compile one .myc file into object file (.o) for linking
             ;   ./myc-llvm o file.myc file.o
             ;   cat file.myc | ./myc-llvm o file.o

  dump|d     ; output backend IR to console (for debugging and optimization analysis)
             ;   ./myc-llvm d file.myc
             ;   cat file.myc | ./myc-llvm d

  format|f   ; formatter
             ;   ./myc-llvm f .

  merge|m    ; merge multiple .myc files into one, output to stdout
             ;   ./myc-llvm m dir/*.myc > summary.myc

  version|v  ; display version information
             ;   ./myc-llvm version

OPTIONS:
  --final ; Slow compilation, for final build only.
  --target=TARGET   (TARGET: arm64, x86_64, x86, ...; default: native)
```

</details>



# mycc - an alternative C compiler, implemented as a POC for fun.

As a proof of concept, over the course of 3 weeks and 2900 lines of code, I implemented mycc: a compiler for a subset of the C language (roughly close to the C99 standard) built on top of myc. Mycc already successfully compiles and runs [LangArena](https://github.com/kostya/LangArena) - a benchmark suite consisting of 50 tests and 9,000 lines of non-trivial C code (json, base64, multithreaded matmul, neural net, compression, maze A*, bf interpreter, and others) with heavy macros like uthash. For the parser, I used libclang - it's an overhead, but it's the simplest solution for a POC.

## How it works:

`C source -> SyntaxTree(libclang/clang.cr) -> TypedAST(mycc) -> IR(myc) -> [LLVM/QBE/C] -> binary`

The most challenging part was `SyntaxTree -> TypedAST`. In the file [ast_builder.cr](https://github.com/kostya/myc/blob/master/src/mycc/ast_builder.cr) contains 1700 lines of code. libclang returns a non-normalized Tree with many edge cases that need to be transformed into a consistent form. Additionally, C has a ton of implicit behavior. Only the edge cases necessary for compiling LangArena are implemented here; there's likely still a lot uncovered.

The `TypedAST(mycc) -> IR(myc)` stage as expected, is one of the simplest ([codegen.cr](https://github.com/kostya/myc/blob/master/src/mycc/codegen.cr), 700 lines) - a single-pass generation of stack-based IR directly from the AST.

### Difference from Clang:

clang: `C -> Parse(libclang) -> Clang CodeGen -> LLVM -> binary`

mycc: `C -> Parse(libclang) -> mycc CodeGen -> IR(myc) -> [LLVM/QBE/C] -> binary`

### Limitations: 

Rare features are not implemented: 2D VLA, complex numbers, longjmp, bitfields, asm, volatile, and anonymous nested structs. I wouldn't try building Linux or sqlite with it. It has only been tested on arm64 and linux64.

## LangArena Benchmark:

Compares Clang, Gcc, Cproc(QBE), and Mycc on [LangArena benchmark](https://github.com/kostya/LangArena).

The `./c` directory of LangArena contains 29 `.c` files (230KB total). All compilers build these files sequentially without using cache or threads. Link time is not counted - it's roughly 50ms for all, and precompiled dependencies were also used. The results show:
- `Build time` total build time for all 29 files
- `Build rss` average RSS during compilation per file
- `Bench Runtime` benchmark execution time

This is not just a random benchmark - each of the 50 LangArena tests validates its output using checksums. A compiler cannot "cheat" by deleting or skip work. This benchmark is also a part of CI.

To run it: `cd benchmark; ruby run_lang_arena.rb`, needs to add cproc,qbe,clang,gcc to PATH, compile `mycc` and install uthash and pcre2 (`sudo apt install uthash-dev libpcre2-dev`).

Results for linux64, gcc 13.3, clang 20.1.

| Compiler | Build time | Build rss | Bench Runtime |
|:-------|-------------:|-----:|----:|
| clang(-O3) | 3113ms | 105Mb | 52.2s |
| clang(-O1) | 2790ms | 104Mb | 54.5s |
| clang(-O0) | 1674ms | 98Mb | 141.0s |
| gcc(-O3) | 3489ms | 34Mb | 52.5s |
| cproc | 761ms | 12Mb | 72.8s |
| mycc(llvm) | 3386ms | 99Mb | 60.0s |
| mycc(qbe) | 2872ms | 87Mb | 67.9s |
| mycc(c, clang) | 4728ms | 102Mb | 57.5s |
| mycc(c, gcc) | 3900ms | 87Mb | 60.2s |
| mycc(llvm, final) | 4317ms | 102Mb | 53.2s |
| mycc(qbe, final) | 2858ms | 87Mb | 68.0s |
| mycc(c, final, clang) | 5166ms | 103Mb | 52.2s |
| mycc(c, final, gcc) | 5178ms | 87Mb | 53.5s |

Currently, mycc is slower at compile time in the benchmarks. Run time for final is close, for default is 5-15% slower as expected. This is due to several suboptimal stages:
- libclang adds parsing overhead of about 30-60ms per file (which is huge).
- IR is generated as text and then parsed again, this adds another ~10ms of overhead per file (also, because of this, error locations are not yet available).


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

# New inliner (did I beat gcc and clang?).

A week after the mycc release, I added an optimization pass - inlining. Here are the results. I also changed the default compilation mode - now it's like Golang: fast compilation and decent runtime.

### LangArena benchmark without mycc overhead:

| Compiler | Build time | Runtime |
|:-------|-------------:|-----:|
| clang(-O3) | 3113ms | 52.2s |
| clang(-O1) | 2790ms | 54.5s |
| clang(-O0) | 1674ms | 141.0s |
| gcc(-O3) | 3489ms | 52.5s |
| cproc | 761ms | 72.8s |
| myc-llvm(default) | **903ms** | **59.7s** |
| myc-llvm(final) | 1843ms | 53.6s |
| myc-qbe(default) | **469ms** | **68.1s** |
| myc-c(default, clang) | 2000ms | 60.6s |
| myc-c(final, clang) | 3351ms | 53.1s |

To get clean measurements, I saved all IR files generated by mycc: `mycc file.c d > file.myc` into the [LangArena/myc](https://github.com/kostya/LangArena/tree/master/myc) directory. This removes libclang overhead and double IR conversion (current mycc pain points) from the measurements. Essentially, this is pure Myc IR -> binary compilation time, without the C parser for LangArena benchmark. You could argue that comparing without C parsing isn't fair. And you'd be right. But let's be honest - mycc's C parsing is very rough and add big overhead (libclang adds up to 60ms per file). If I write a proper fast parser for C like cproc did, it would add an estimated ~300ms to the compilation time (based on cproc minus myc-qbe results). But I don't want to invest time in the C frontend right now - mycc is a POC, a tool to generate IR for testing Myc.

Did I beat clang and gcc like I originally wanted? On runtime alone - no. But on compile time vs runtime ratio - I think I did. At least this result satisfy me. Just keep in mind you'd need to add C parsing time (~300ms est.) to build time.


Steps to reproduce (work on linux64, failed to link on macos arm64):
```
git clone https://github.com/kostya/LangArena.git plugins/LangArena

# need precompile dependencies for linking (yyjson.o, libbase64.o):
cd plugins/LangArena/c; make prod; cd ../../../

# ------ LLVM -------
time MYC_LINKER_FLAGS='-lpcre2-8 plugins/LangArena/c/target/deps/prod/libbase64.o plugins/LangArena/c/target/deps/prod/yyjson.o' ./myc-llvm plugins/LangArena/myc/*.myc c bin_langarena_mycc_llvm
# compiled to bin_langarena_mycc_llvm
# real  0m0.858s
# user  0m0.819s
# sys 0m0.039s

./bin_langarena_mycc_llvm plugins/LangArena/run.js
# Summary: 59.3423s, 50, 50, 0

# ------ QBE -------
time MYC_LINKER_FLAGS='-lpcre2-8 plugins/LangArena/c/target/deps/prod/libbase64.o plugins/LangArena/c/target/deps/prod/yyjson.o' ./myc-qbe plugins/LangArena/myc/*.myc c bin_langarena_mycc_qbe
# compiled to bin_langarena_mycc_qbe
# real  0m0.482s
# user  0m0.338s
# sys 0m0.148s

./bin_langarena_mycc_qbe plugins/LangArena/run.js
# Summary: 68.4695s, 50, 50, 0

```


## License

Licensed under the Apache License, Version 2.0.

## Thanks

- [Crystal language](https://crystal-lang.org)
- [QBE](https://c9x.me/compile/)
- [LLVM](https://llvm.org/)
- [clang.cr](https://github.com/crystal-lang/clang.cr)
