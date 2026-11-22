require "./spec_helper"

class Myc::Backend::Mycc::Backend
  def spec_dump_mycc(input : String, output : String)
    mod, header = load_single(input)
    dump(mod, header, output)
  end
end

def with_mycc(source : String, opt = "debug", backend : String? = nil, ext = "c", &) : String
  data = Myc::Cli::Data.new
  if backend
    data.options["backend"] = backend
  end
  if opt == "debug"
    data.options["debug"] = ""
  elsif opt == "default"
  elsif opt == "final"
    data.options["final"] = ""
  end
  input = Myc::Backend::AbstractBackend.new_tmp_path("mycc-dump", ext)
  File.open(input, "w") { |f| f.puts(source) }
  output = Myc::Backend::AbstractBackend.new_tmp_path("mycc-dump", "myc")
  data.files_to_cleanup << input
  data.files_to_cleanup << output
  data.values << input
  data.values << output
  backend = Myc::Backend::Mycc::Backend.new(data)
  yield backend, input, output
  res = File.read(output).strip
  if ENV["MYC_VERBOSE"]? == "1"
    puts res
  end
  res
ensure
  data.not_nil!.clean_temp_files
end

def mycc_dump(source : String, opt = "debug", backend : String? = nil) : String
  with_mycc(source, opt, backend) { |backend, input, output| backend.spec_dump_mycc(input, output) }
end

def myc_dump(source : String, opt = "debug", backend : String? = nil) : String
  with_mycc(source, opt, backend, "myc") { |backend, input, output| backend.spec_dump_mycc(input, output) }
end

context "mycc dump" do
  it "test myc" do
    mycc_dump(<<-'______________SOURCE').should eq <<-'______________RESULT'.strip
      int main() {
        int x = 1 + 2;
        return x;
      }
    ______________SOURCE
    FUNC :main
      RETURN
        TYPE :i32
      BODY
        PUSH 2
        PUSH 1
        BINARY :add
        LOCAL :__s0_x :i32
        STORE
        LOCAL :__s0_x
        RET
    ENDFUNC
    ______________RESULT
  end

  it "test llvm" do
    mycc_dump(<<-'______________SOURCE', backend: "LLVM").should contain <<-'______________RESULT'.strip
      int main() {
        int x = 1 + 2;
        return x;
      }
    ______________SOURCE
    alloca:
      %__s0_x = alloca i32, align 4
      br label %body

    body:                                             ; preds = %alloca
      store i32 3, ptr %__s0_x, align 4
      %0 = load i32, ptr %__s0_x, align 4
      ret i32 %0
    }
    ______________RESULT
  end

  it "test qbe" do
    mycc_dump(<<-'______________SOURCE', backend: "QBE").should contain <<-'______________RESULT'.strip
      int main() {
        int x = 1 + 2;
        return x;
      }
    ______________SOURCE
    export function w $main() {
    @start
      %__s0_x =l alloc4 4
      jmp @body
    @body
      %t1 =w add 1, 2
      storew %t1, %__s0_x
      %t2 =w loadw %__s0_x
      ret %t2
    }
    ______________RESULT
  end

  if GM_ENABLED && GM_SPEC_BACKEND
    it "test gm" do
      mycc_dump(<<-'______________SOURCE', backend: "GM").should contain <<-'______________RESULT'.strip
      int main() {
        int x = 1 + 2;
        return x;
      }
    ______________SOURCE
    function @main() -> i32 [role=entry, linkage=c, binding=strong] {
      slot $0 : i32

      block ^0:
        jump ^1

      block ^1:
        %t1 = binary add i32 1, 2
        store i32 %t1, $0
        %t2 = load typed i32 $0
        return i32 %t2
    }
    ______________RESULT
    end
  end

  it "test c" do
    mycc_dump(<<-'______________SOURCE', backend: "C").should contain <<-'______________RESULT'.strip
      int main() {
        int x = 1 + 2;
        return x;
      }
    ______________SOURCE
    __attribute__((noinline)) int32_t main(int arg0, char *_arg1[]) {
    uint8_t** arg1 = (uint8_t**)_arg1;
      int32_t __s0_x;
      int32_t t1 = 1 + 2;
      __s0_x = t1;
      int32_t t2 = __s0_x;
      return t2;
    }
    ______________RESULT
  end
end

context "dump more" do
  it "myc types" do
    mycc_dump(<<-'______________SOURCE').should eq <<-'______________RESULT'.strip
      struct Bla { int x; };
      int main() {
        struct Bla bla = {42};
        return bla.x;
      }
    ______________SOURCE
    STRUCT :Bla
      TYPE :i32
    ENDSTRUCT

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        PUSH 42
        CREATE :Bla
        LOCAL :__s0_bla :Bla
        STORE
        LOCAL :__s0_bla
        FIELD 0
        RET
    ENDFUNC
    ______________RESULT
  end

  it "myc types enum" do
    mycc_dump(<<-'______________SOURCE').should eq <<-'______________RESULT'.strip
      union Bla { int x; double y; };
      int main() {
        union Bla bla = {.x = 42};
        return bla.x;
      }
    ______________SOURCE
    ENUM :Bla
      TAG
        SKIP
      VARIANT :x
        TYPE :i32
      VARIANT :y
        TYPE :f64
    ENDENUM

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        PUSH 42
        CREATE :Bla::x
        AS :Bla
        LOCAL :__s0_bla :Bla
        STORE
        LOCAL :__s0_bla
        AS :Bla::x
        FIELD 1
        RET
    ENDFUNC
    ______________RESULT
  end

  it "myc global" do
    mycc_dump(<<-'______________SOURCE').should eq <<-'______________RESULT'.strip
      int x = 42;
      int main() {
        return x;
      }
    ______________SOURCE
    GLOBAL :x
      TYPE :i32
      INITIAL 42
    ENDGLOBAL

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        GLOBAL :x
        RET
    ENDFUNC
    ______________RESULT
  end

  it "myc func" do
    mycc_dump(<<-'______________SOURCE').should eq <<-'______________RESULT'.strip
      int test() { return 42; }
      int main() {
        return test();
      }
    ______________SOURCE
    FUNC :test
      RETURN
        TYPE :i32
      BODY
        PUSH 42
        RET
    ENDFUNC

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        CALL :test
        RET
    ENDFUNC
    ______________RESULT
  end
end

context "myc inliner" do
  it "1" do
    myc_dump(<<-'______________SOURCE', opt: "default").should eq <<-'______________RESULT'.strip
    FUNC :add
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        PARAM 0
        BINARY :add
        RET
    ENDFUNC

    FUNC :test_inline
      BODY
        PUSH 10
        PUSH 5
        CALL :add
        INSPECT
    ENDFUNC

    FUNC :main
      BODY
        CALL :test_inline
    ENDFUNC
    ______________SOURCE
    FUNC :add
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        PARAM 0
        BINARY :add
        RET
    ENDFUNC

    FUNC :test_inline
      BODY
        PUSH 10
        PUSH 5
        TO :i32
        SLOT :__add_0_0_0
        TO :i32
        SLOT :__add_0_0_1
        SLOT :__add_0_0_1
        SLOT :__add_0_0_0
        BINARY :add
        SLOT :__add_0_0_ret
        SLOT :__add_0_0_ret
        INSPECT
    ENDFUNC

    FUNC :main
      BODY
        PUSH 10
        PUSH 5
        TO :i32
        SLOT :__test_inline_1_0___add_0_0_0
        TO :i32
        SLOT :__test_inline_1_0___add_0_0_1
        SLOT :__test_inline_1_0___add_0_0_1
        SLOT :__test_inline_1_0___add_0_0_0
        BINARY :add
        SLOT :__test_inline_1_0___add_0_0_ret
        SLOT :__test_inline_1_0___add_0_0_ret
        INSPECT
    ENDFUNC
    ______________RESULT
  end

  it "2" do
    myc_dump(<<-'______________SOURCE', opt: "default").should eq <<-'______________RESULT'.strip
    STRUCT :S
      TYPE :i32
    ENDSTRUCT

    GLOBAL :G
      TYPE :S
      INITIAL 5
      CONSTANT
    ENDGLOBAL

    FUNC :get
      ARGS
        TYPE :ptr<S>
      RETURN
        TYPE :i32
      BODY
        PARAM 0
        DEREF
        FIELD 0
        RET
    ENDFUNC

    FUNC :empty
      ARGS
        TYPE :ptr<S>
      RETURN
        TYPE :bool
      BODY
        PUSH 0
        PARAM 0
        CALL :get
        BINARY :eq
        RET
    ENDFUNC

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        GLOBAL :G
        ADDR
        LOCAL :s :ptr<S>
        STORE
        LOCAL :s
        CALL :empty
        INSPECT
        LOCAL :s
        CALL :empty
        INSPECT
        PUSH 0
        RET
    ENDFUNC
    ______________SOURCE
    STRUCT :S
      TYPE :i32
    ENDSTRUCT

    GLOBAL :G
      TYPE :S
      INITIAL 5
      CONSTANT
    ENDGLOBAL

    FUNC :get
      ARGS
        TYPE :ptr<S>
      RETURN
        TYPE :i32
      BODY
        PARAM 0
        DEREF
        FIELD 0
        RET
    ENDFUNC

    FUNC :empty
      ARGS
        TYPE :ptr<S>
      RETURN
        TYPE :bool
      BODY
        PUSH 0
        PARAM 0
        TO :ptr<S>
        SLOT :__get_0_0_0
        SLOT :__get_0_0_0
        DEREF
        FIELD 0
        SLOT :__get_0_0_ret
        SLOT :__get_0_0_ret
        BINARY :eq
        RET
    ENDFUNC

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        GLOBAL :G
        ADDR
        LOCAL :s :ptr<S>
        STORE
        LOCAL :s
        TO :ptr<S>
        SLOT :__empty_1_0_0
        PUSH 0
        SLOT :__empty_1_0_0
        TO :ptr<S>
        SLOT :__empty_1_0___get_0_0_0
        SLOT :__empty_1_0___get_0_0_0
        DEREF
        FIELD 0
        SLOT :__empty_1_0___get_0_0_ret
        SLOT :__empty_1_0___get_0_0_ret
        BINARY :eq
        SLOT :__empty_1_0_ret
        SLOT :__empty_1_0_ret
        INSPECT
        LOCAL :s
        TO :ptr<S>
        SLOT :__empty_1_1_0
        PUSH 0
        SLOT :__empty_1_1_0
        TO :ptr<S>
        SLOT :__empty_1_1___get_0_0_0
        SLOT :__empty_1_1___get_0_0_0
        DEREF
        FIELD 0
        SLOT :__empty_1_1___get_0_0_ret
        SLOT :__empty_1_1___get_0_0_ret
        BINARY :eq
        SLOT :__empty_1_1_ret
        SLOT :__empty_1_1_ret
        INSPECT
        PUSH 0
        RET
    ENDFUNC
    ______________RESULT
  end

  it "3" do
    myc_dump(<<-'______________SOURCE', opt: "default").should eq <<-'______________RESULT'.strip
    FUNC :add
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        SLOT :a
        PARAM 0
        SLOT :b
        SLOT :a
        SLOT :b
        BINARY :add
        RET
    ENDFUNC

    FUNC :test_inline
      BODY
        PUSH 10
        PUSH 5
        CALL :add
        INSPECT
    ENDFUNC

    FUNC :main
      BODY
        CALL :test_inline
    ENDFUNC
    ______________SOURCE
    FUNC :add
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        SLOT :a
        PARAM 0
        SLOT :b
        SLOT :a
        SLOT :b
        BINARY :add
        RET
    ENDFUNC

    FUNC :test_inline
      BODY
        PUSH 10
        PUSH 5
        TO :i32
        SLOT :__add_0_0_0
        TO :i32
        SLOT :__add_0_0_1
        SLOT :__add_0_0_1
        SLOT :__add_0_0_a
        SLOT :__add_0_0_0
        SLOT :__add_0_0_b
        SLOT :__add_0_0_a
        SLOT :__add_0_0_b
        BINARY :add
        SLOT :__add_0_0_ret
        SLOT :__add_0_0_ret
        INSPECT
    ENDFUNC

    FUNC :main
      BODY
        PUSH 10
        PUSH 5
        TO :i32
        SLOT :__test_inline_1_0___add_0_0_0
        TO :i32
        SLOT :__test_inline_1_0___add_0_0_1
        SLOT :__test_inline_1_0___add_0_0_1
        SLOT :__test_inline_1_0___add_0_0_a
        SLOT :__test_inline_1_0___add_0_0_0
        SLOT :__test_inline_1_0___add_0_0_b
        SLOT :__test_inline_1_0___add_0_0_a
        SLOT :__test_inline_1_0___add_0_0_b
        BINARY :add
        SLOT :__test_inline_1_0___add_0_0_ret
        SLOT :__test_inline_1_0___add_0_0_ret
        INSPECT
    ENDFUNC
    ______________RESULT
  end

  it "recursion not inlined" do
    myc_dump(<<-'______________SOURCE', opt: "default").should eq <<-'______________RESULT'.strip
    FUNC :factorial
      ARGS
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PUSH 1
        PARAM 0
        BINARY :less_eq
        IF
          THEN
            PUSH 1
            RET
        ENDIF
        PARAM 0
        PUSH 1
        PARAM 0
        BINARY :sub
        CALL :indirect
        BINARY :mul
        RET
    ENDFUNC

    FUNC :indirect
      ARGS
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 0
        CALL :factorial
        RET
    ENDFUNC

    FUNC :main
      BODY
        PUSH 5
        CALL :factorial
        INSPECT
    ENDFUNC
    ______________SOURCE
    FUNC :factorial
      ARGS
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PUSH 1
        PARAM 0
        BINARY :less_eq
        IF
          THEN
            PUSH 1
            RET
        ENDIF
        PARAM 0
        PUSH 1
        PARAM 0
        BINARY :sub
        CALL :indirect
        BINARY :mul
        RET
    ENDFUNC

    FUNC :indirect
      ARGS
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 0
        CALL :factorial
        RET
    ENDFUNC

    FUNC :main
      BODY
        PUSH 5
        CALL :factorial
        INSPECT
    ENDFUNC
    ______________RESULT
  end
end

context "mycc inliner" do
  it "1" do
    mycc_dump(<<-'______________SOURCE', opt: "default").should eq <<-'______________RESULT'.strip
    int add(int a, int b) { return a + b; }
    int test_inline() { return add(5, 10); }
    int main() { return test_inline(); }
    ______________SOURCE
    FUNC :add
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        PARAM 0
        BINARY :add
        RET
    ENDFUNC

    FUNC :test_inline
      RETURN
        TYPE :i32
      BODY
        PUSH 10
        PUSH 5
        TO :i32
        SLOT :__add_0_0_0
        TO :i32
        SLOT :__add_0_0_1
        SLOT :__add_0_0_1
        SLOT :__add_0_0_0
        BINARY :add
        SLOT :__add_0_0_ret
        SLOT :__add_0_0_ret
        RET
    ENDFUNC

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        PUSH 10
        PUSH 5
        TO :i32
        SLOT :__test_inline_1_0___add_0_0_0
        TO :i32
        SLOT :__test_inline_1_0___add_0_0_1
        SLOT :__test_inline_1_0___add_0_0_1
        SLOT :__test_inline_1_0___add_0_0_0
        BINARY :add
        SLOT :__test_inline_1_0___add_0_0_ret
        SLOT :__test_inline_1_0___add_0_0_ret
        SLOT :__test_inline_1_0_ret
        SLOT :__test_inline_1_0_ret
        RET
    ENDFUNC
    ______________RESULT
  end

  it "2" do
    mycc_dump(<<-'______________SOURCE', opt: "default").should eq <<-'______________RESULT'.strip
    struct S { int x; };
    struct S G = {5};
    int get(struct S* s) { return s->x; }
    int empty(struct S* s) { return get(s) == 0; }
    int main() { struct S*s = &G; return empty(s); }
    ______________SOURCE
    STRUCT :S
      TYPE :i32
    ENDSTRUCT

    GLOBAL :G
      TYPE :S
      INITIAL 5
    ENDGLOBAL

    FUNC :get
      ARGS
        TYPE :ptr<S>
      RETURN
        TYPE :i32
      BODY
        PARAM 0
        DEREF
        FIELD 0
        RET
    ENDFUNC

    FUNC :empty
      ARGS
        TYPE :ptr<S>
      RETURN
        TYPE :i32
      BODY
        PUSH 0
        PARAM 0
        TO :ptr<S>
        SLOT :__get_0_0_0
        SLOT :__get_0_0_0
        DEREF
        FIELD 0
        SLOT :__get_0_0_ret
        SLOT :__get_0_0_ret
        BINARY :eq
        AS :i32
        RET
    ENDFUNC

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        GLOBAL :G
        ADDR
        LOCAL :__s0_s :ptr<S>
        STORE
        LOCAL :__s0_s
        TO :ptr<S>
        SLOT :__empty_1_0_0
        PUSH 0
        SLOT :__empty_1_0_0
        TO :ptr<S>
        SLOT :__empty_1_0___get_0_0_0
        SLOT :__empty_1_0___get_0_0_0
        DEREF
        FIELD 0
        SLOT :__empty_1_0___get_0_0_ret
        SLOT :__empty_1_0___get_0_0_ret
        BINARY :eq
        AS :i32
        SLOT :__empty_1_0_ret
        SLOT :__empty_1_0_ret
        RET
    ENDFUNC
    ______________RESULT
  end

  it "3" do
    mycc_dump(<<-'______________SOURCE', opt: "default").should eq <<-'______________RESULT'.strip
    int add(int a, int b) { return a + b; }
    int add2(int a, int b) { return add(a, b); }
    int add3(int a, int b) { return add2(a, b); }
    int add4(int a, int b) { return add3(a, b); }
    int main() { return add4(5, 10); }
    ______________SOURCE
    FUNC :add
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        PARAM 0
        BINARY :add
        RET
    ENDFUNC

    FUNC :add2
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        PARAM 0
        TO :i32
        SLOT :__add_0_0_0
        TO :i32
        SLOT :__add_0_0_1
        SLOT :__add_0_0_1
        SLOT :__add_0_0_0
        BINARY :add
        SLOT :__add_0_0_ret
        SLOT :__add_0_0_ret
        RET
    ENDFUNC

    FUNC :add3
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        PARAM 0
        TO :i32
        SLOT :__add2_1_0_0
        TO :i32
        SLOT :__add2_1_0_1
        SLOT :__add2_1_0_1
        SLOT :__add2_1_0_0
        TO :i32
        SLOT :__add2_1_0___add_0_0_0
        TO :i32
        SLOT :__add2_1_0___add_0_0_1
        SLOT :__add2_1_0___add_0_0_1
        SLOT :__add2_1_0___add_0_0_0
        BINARY :add
        SLOT :__add2_1_0___add_0_0_ret
        SLOT :__add2_1_0___add_0_0_ret
        SLOT :__add2_1_0_ret
        SLOT :__add2_1_0_ret
        RET
    ENDFUNC

    FUNC :add4
      ARGS
        TYPE :i32
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 1
        PARAM 0
        TO :i32
        SLOT :__add3_2_0_0
        TO :i32
        SLOT :__add3_2_0_1
        SLOT :__add3_2_0_1
        SLOT :__add3_2_0_0
        TO :i32
        SLOT :__add3_2_0___add2_1_0_0
        TO :i32
        SLOT :__add3_2_0___add2_1_0_1
        SLOT :__add3_2_0___add2_1_0_1
        SLOT :__add3_2_0___add2_1_0_0
        TO :i32
        SLOT :__add3_2_0___add2_1_0___add_0_0_0
        TO :i32
        SLOT :__add3_2_0___add2_1_0___add_0_0_1
        SLOT :__add3_2_0___add2_1_0___add_0_0_1
        SLOT :__add3_2_0___add2_1_0___add_0_0_0
        BINARY :add
        SLOT :__add3_2_0___add2_1_0___add_0_0_ret
        SLOT :__add3_2_0___add2_1_0___add_0_0_ret
        SLOT :__add3_2_0___add2_1_0_ret
        SLOT :__add3_2_0___add2_1_0_ret
        SLOT :__add3_2_0_ret
        SLOT :__add3_2_0_ret
        RET
    ENDFUNC

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        PUSH 10
        PUSH 5
        TO :i32
        SLOT :__add4_3_0_0
        TO :i32
        SLOT :__add4_3_0_1
        SLOT :__add4_3_0_1
        SLOT :__add4_3_0_0
        TO :i32
        SLOT :__add4_3_0___add3_2_0_0
        TO :i32
        SLOT :__add4_3_0___add3_2_0_1
        SLOT :__add4_3_0___add3_2_0_1
        SLOT :__add4_3_0___add3_2_0_0
        TO :i32
        SLOT :__add4_3_0___add3_2_0___add2_1_0_0
        TO :i32
        SLOT :__add4_3_0___add3_2_0___add2_1_0_1
        SLOT :__add4_3_0___add3_2_0___add2_1_0_1
        SLOT :__add4_3_0___add3_2_0___add2_1_0_0
        TO :i32
        SLOT :__add4_3_0___add3_2_0___add2_1_0___add_0_0_0
        TO :i32
        SLOT :__add4_3_0___add3_2_0___add2_1_0___add_0_0_1
        SLOT :__add4_3_0___add3_2_0___add2_1_0___add_0_0_1
        SLOT :__add4_3_0___add3_2_0___add2_1_0___add_0_0_0
        BINARY :add
        SLOT :__add4_3_0___add3_2_0___add2_1_0___add_0_0_ret
        SLOT :__add4_3_0___add3_2_0___add2_1_0___add_0_0_ret
        SLOT :__add4_3_0___add3_2_0___add2_1_0_ret
        SLOT :__add4_3_0___add3_2_0___add2_1_0_ret
        SLOT :__add4_3_0___add3_2_0_ret
        SLOT :__add4_3_0___add3_2_0_ret
        SLOT :__add4_3_0_ret
        SLOT :__add4_3_0_ret
        RET
    ENDFUNC
    ______________RESULT
  end

  it "3 and qbe" do
    mycc_dump(<<-'______________SOURCE', opt: "default", backend: "QBE").should eq <<-'______________RESULT'.strip
    int add(int a, int b) { return a + b; }
    int add2(int a, int b) { return add(a, b); }
    int add3(int a, int b) { return add2(a, b); }
    int add4(int a, int b) { return add3(a, b); }
    int main() { return add4(5, 10); }
    ______________SOURCE
    export function w $add(w %arg0, w %arg1) {
    @start
      jmp @body
    @body
      %t1 =w add %arg0, %arg1
      ret %t1
    }

    export function w $add2(w %arg0, w %arg1) {
    @start
      jmp @body
    @body
      %t1 =w add %arg0, %arg1
      ret %t1
    }

    export function w $add3(w %arg0, w %arg1) {
    @start
      jmp @body
    @body
      %t1 =w add %arg0, %arg1
      ret %t1
    }

    export function w $add4(w %arg0, w %arg1) {
    @start
      jmp @body
    @body
      %t1 =w add %arg0, %arg1
      ret %t1
    }

    export function w $main() {
    @start
      jmp @body
    @body
      %t1 =w add 5, 10
      ret %t1
    }
    ______________RESULT
  end

  it "recursion not inlined" do
    mycc_dump(<<-'______________SOURCE', opt: "default").should eq <<-'______________RESULT'.strip
    int indirect(int a);
    int fact(int x) {
      if (x < 1) return 1;
      return x * indirect(x - 1);
    }
    int indirect(int a) { return fact(a); }
    int main() { return fact(5); }
    ______________SOURCE
    FUNC :indirect
      ARGS
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PARAM 0
        CALL :fact
        RET
    ENDFUNC

    FUNC :fact
      ARGS
        TYPE :i32
      RETURN
        TYPE :i32
      BODY
        PUSH 1
        PARAM 0
        BINARY :less
        IF
          THEN
            PUSH 1
            RET
        ENDIF
        PUSH 1
        PARAM 0
        BINARY :sub
        CALL :indirect
        PARAM 0
        BINARY :mul
        RET
    ENDFUNC

    FUNC :main
      RETURN
        TYPE :i32
      BODY
        PUSH 5
        CALL :fact
        RET
    ENDFUNC
    ______________RESULT
  end
end
