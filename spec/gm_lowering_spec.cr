require "./spec_helper"

# Exercise the public LowIR view and owned construction buffers without
# depending on the host's ability to execute x86 objects (e.g. ARM macOS CI).
class Myc::Backend::GM::Backend
  def spec_dump_lowir(input : String, output : String)
    mod, header = load_single(input)
    dump(mod, header, output)
  end

  def spec_with_function(input : String, &)
    mod, header = load_single(input)
    builder = new_builder.as(Myc::Backend::GM::Builder)
    begin
      yield builder.new_func(mod.func_defs["probe"], header).as(Myc::Backend::GM::Func)
    ensure
      builder.close
    end
  end
end

def with_gm_source(source : String, &)
  data = Myc::Cli::Data.new
  data.options["target"] = "x86_64-unknown-linux-gnu"
  data.options["debug"] = ""
  input = Myc::Backend::AbstractBackend.new_tmp_path("gm-lowering", "myc")
  output = Myc::Backend::AbstractBackend.new_tmp_path("gm-lowering", "lowir")
  File.write(input, source)
  begin
    yield Myc::Backend::GM::Backend.new(data), input, output
  ensure
    File.delete(input) if File.exists?(input)
    File.delete(output) if File.exists?(output)
    data.clean_temp_files
  end
end

def gm_lowir(source : String) : String
  with_gm_source(source) do |backend, input, output|
    backend.spec_dump_lowir(input, output)
    File.read(output)
  end
end

if (ENV["BACKEND"]? || "gm").split(',').any? { |backend| backend.strip.downcase.starts_with?("gm") }
  describe "GM LowIR lowering" do
    it "returns scalar SSA values from each branch without a result slot" do
      text = gm_lowir(<<-MYC)
      FUNC :probe
        ARGS
          TYPE :bool
        RETURN
          TYPE :i32
        BODY
          PARAM 0
          IF
            THEN
              PUSH 42
              RET
            ELSE
              PUSH 7
              RET
          ENDIF
      ENDFUNC
      MYC
      text.should contain("return i32 42")
      text.should contain("return i32 7")
      text.should_not contain("slot ")
      text.should_not contain("store ")
      text.should_not contain("= load ")
    end

    it "uses one block for empty, straight-line and explicit void-return functions" do
      ["", "PUSH 1\n    STACK :drop", "RET"].each do |body|
        text = gm_lowir("FUNC :probe\n  BODY\n    #{body}\nENDFUNC\n")
        text.lines.count { |line| line.starts_with?("  block ") }.should eq 1
        text.should contain("return void")
        text.should_not contain("jump ")
      end
    end

    it "returns a scalar from a single entry block even with a local slot" do
      text = gm_lowir(<<-MYC)
      FUNC :probe
        RETURN
          TYPE :i32
        BODY
          PUSH 42
          LOCAL :value :i32
          STORE
          LOCAL :value
          RET
      ENDFUNC
      MYC
      text.lines.count { |line| line.starts_with?("  block ") }.should eq 1
      text.should contain("store i32 42")
      text.should contain("return i32")
      text.should_not contain("jump ")
      text.should_not contain("unreachable")
    end

    it "keeps aggregate parameter copies before body reads and an owned return exit" do
      text = gm_lowir(<<-MYC)
      STRUCT :Pair
        TYPE :i32
        TYPE :i32
      ENDSTRUCT
      FUNC :probe
        ARGS
          TYPE :Pair
        RETURN
          TYPE :Pair
        BODY
          PARAM 0
          LOCAL :copy :Pair
          STORE
          PUSH 42
          LOCAL :copy
          FIELD 0
          STORE
          LOCAL :copy
          RET
      ENDFUNC
      MYC
      text.lines.count { |line| line.starts_with?("  block ") }.should eq 2
      text.should contain("copyobj")
      text.should contain("return obj<8x4>")
      text.index("copyobj").not_nil!.should be < text.index("store i32 42").not_nil!
    end

    it "preserves readonly storage, size and alignment while compacting zero data" do
      text = gm_lowir(<<-MYC)
      GLOBAL :data
        TYPE :flat<i64,4096>
        INITIAL
        CONSTANT
      ENDGLOBAL
      FUNC :probe
        BODY
      ENDFUNC
      MYC
      text.should contain("obj<32768x8>")
      text.should contain("storage=readonly")
      text.should contain("zero 32768")
      text.lines.size.should be < 25
    end

    it "uses symbol addresses without manufacturing address temporaries" do
      text = gm_lowir(<<-MYC)
      FUNC :probe
        RETURN
          TYPE :ptr<u8>
        BODY
          PUSH "abc"
          RET
      ENDFUNC
      MYC
      text.should contain("return ptr @str_0")
      text.should_not contain("= addr ")
    end

    it "carries allocation bounds for field and element addressing" do
      text = gm_lowir(<<-MYC)
      FUNC :field
        ARGS
          TYPE :ptr<struct<i32,i64>>
        RETURN
          TYPE :ptr<i64>
        BODY
          PARAM 0
          DEREF
          FIELD 1
          ADDR
          RET
      ENDFUNC
      FUNC :probe
        ARGS
          TYPE :ptr<i32>
          TYPE :i64
        RETURN
          TYPE :ptr<i32>
        BODY
          PARAM 1
          PARAM 0
          BINARY :add
          RET
      ENDFUNC
      MYC
      text.should contain("index inbounds i8")
      text.should contain("index inbounds i32")
      text.should_not contain("nowrap")
    end

    it "shares literal bits without merging negative zero or changing their kinds" do
      with_gm_source("FUNC :probe\n  BODY\nENDFUNC\n") do |backend, input, _|
        backend.spec_with_function(input) do |func|
          zero = func.integer(0)
          one = func.integer(1)
          minus_one = func.integer(-1)
          func.integer(0).index.should eq zero.index
          func.integer(1).index.should eq one.index
          func.integer(-1).index.should eq minus_one.index
          float_zero = func.literal(Myc::Backend::GM::IRKind::Float, 0_u64, 0_u64, Myc::Backend::GM::IRType::F64)
          float_zero.index.should eq zero.index
          float_zero.kind.should eq Myc::Backend::GM::IRKind::Float.value
          float_zero.float_kind.should eq Myc::Backend::GM::IRType::F64.value
          negative_zero = func.literal(Myc::Backend::GM::IRKind::Float, 0x8000000000000000_u64, 0_u64, Myc::Backend::GM::IRType::F64)
          negative_zero.index.should_not eq zero.index
          # Force growth past the initial literal reservation. Cache entries
          # are stable pool IDs, never pointers into the old allocation.
          (2..64).each { |i| func.integer(i) }
          func.integer(0).index.should eq zero.index
          func.integer(1).index.should eq one.index
          func.integer(-1).index.should eq minus_one.index
        end
      end
    end
  end
end
