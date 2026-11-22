require "./spec_helper"

class Myc::Backend::Mycc::Backend
  def spec_dump_mycc(input : String, output : String)
    mod, header = load_single(input)
    dump(mod, header, output)
  end
end

def with_mycc(source : String, backend : String? = nil, &) : String
  data = Myc::Cli::Data.new
  if backend
    data.options["backend"] = backend
  end
  data.options["debug"] = ""
  input = Myc::Backend::AbstractBackend.new_tmp_path("mycc-dump", "c")
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

def mycc_dump(source : String, backend : String? = nil) : String
  with_mycc(source, backend) { |backend, input, output| backend.spec_dump_mycc(input, output) }
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
    mycc_dump(<<-'______________SOURCE', "LLVM").should contain <<-'______________RESULT'.strip
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
    mycc_dump(<<-'______________SOURCE', "QBE").should contain <<-'______________RESULT'.strip
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

  it "test gm" do
    mycc_dump(<<-'______________SOURCE', "GM").should contain <<-'______________RESULT'.strip
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

  it "test c" do
    mycc_dump(<<-'______________SOURCE', "C").should contain <<-'______________RESULT'.strip
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
