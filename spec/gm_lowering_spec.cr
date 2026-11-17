require "./spec_helper"

class Myc::Backend::GM::Backend
  def spec_dump_lowir(input : String, output : String)
    mod, header = load_single(input)
    dump(mod, header, output)
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

if GM_ENABLED
  describe "GM LowIR lowering" do
    it "passes objects as C passes structs with the same fields" do
      text = gm_lowir(<<-MYC)
      STRUCT :Point
        TYPE :f64
        TYPE :f64
      ENDSTRUCT
      STRUCT :Mixed
        TYPE :f64
        TYPE :i64
      ENDSTRUCT
      STRUCT :Floats
        TYPE :f32
        TYPE :f32
      ENDSTRUCT
      STRUCT :Shared
        TYPE :f32
        TYPE :i32
      ENDSTRUCT
      STRUCT :Packed
        ALIGN 1
        TYPE :u8
        TYPE :f64
      ENDSTRUCT
      STRUCT :Large
        TYPE :f64
        TYPE :f64
        TYPE :f64
      ENDSTRUCT
      ENUM :Number
        TAG
          SKIP
        VARIANT :d
          TYPE :f64
        VARIANT :f
          TYPE :f32
      ENDENUM
      FUNC :point
        ARGS
          TYPE :Point
          TYPE :Mixed
        RETURN
          TYPE :Point
      ENDFUNC
      FUNC :floats
        ARGS
          TYPE :Floats
          TYPE :Number
        RETURN
          TYPE :Mixed
      ENDFUNC
      FUNC :defaults
        ARGS
          TYPE :Shared
          TYPE :Large
        RETURN
          TYPE :Shared
      ENDFUNC
      FUNC :packed
        ARGS
          TYPE :Packed
      ENDFUNC
      FUNC :probe
        ARGS
          TYPE :Point
          TYPE :Mixed
          TYPE :Floats
          TYPE :Number
          TYPE :Shared
          TYPE :Large
          TYPE :Packed
        BODY
          PARAM 1
          PARAM 0
          CALL :point
          STACK :drop
          PARAM 3
          PARAM 2
          CALL :floats
          STACK :drop
          PARAM 5
          PARAM 4
          CALL :defaults
          STACK :drop
          PARAM 6
          CALL :packed
      ENDFUNC
      MYC
      text.should contain("@point(%arg0 : obj<16x8> [classes=sse_sse], %arg1 : obj<16x8> [classes=sse_integer]) -> obj<16x8> [result_classes=sse_sse,")

      text.should contain("@floats(%arg0 : obj<8x4> [classes=sse], %arg1 : obj<8x8> [classes=integer]) -> obj<16x8> [result_classes=sse_integer,")

      text.should contain("@defaults(%arg0 : obj<8x4> [classes=integer], %arg1 : obj<24x8>) -> obj<8x4> [result_classes=integer, linkage=c")
      text.should contain("@packed(%arg0 : obj<9x1> [classes=memory])")
    end

    it "passes objects among variable arguments as C passes them" do
      text = gm_lowir(<<-MYC)
      STRUCT :Point
        TYPE :f64
        TYPE :f64
      ENDSTRUCT
      STRUCT :Pair
        TYPE :i32
        TYPE :i32
      ENDSTRUCT
      FUNC :sum
        ARGS
          TYPE :i32
        RETURN
          TYPE :f64
        ATTRIBUTES
          ATTR :vaarg
      ENDFUNC
      FUNC :probe
        ARGS
          TYPE :i32
          TYPE :Point
          TYPE :Pair
        ATTRIBUTES
          ATTR :vaarg
        BODY
          PARAM 0
          LOCAL :list :valist
          VA :start
          LOCAL :list
          VA :arg :Point
          LOCAL :point :Point
          STORE
          LOCAL :list
          VA :arg :Pair
          LOCAL :pair :Pair
          STORE
          PARAM 1
          PARAM 2
          PARAM 1
          PUSH 3
          CALL :sum 3
          STACK :drop
      ENDFUNC
      MYC
      text.should match(/va_arg obj<16x8> %t\d+ \[classes=sse_sse\]\n/)
      text.should match(/va_arg obj<8x4> %t\d+ \[classes=integer_none\]\n/)
      text.should match(/call f64 @sum\(3, %t\d+, %t\d+, %t\d+\) \[classes=1:sse_sse, classes=2:integer_none, classes=3:sse_sse\]/)
    end

    it "keeps a noinline function out of cppgm's inliner" do
      text = gm_lowir(<<-MYC)
      FUNC :kept
        ATTRIBUTES
          ATTR :noinline
        BODY
      ENDFUNC
      FUNC :probe
        BODY
          CALL :kept
      ENDFUNC
      MYC
      text.should contain("function @kept() -> void [linkage=c, binding=strong, no_inline=yes]")
      text.should contain("function @probe() -> void [linkage=c, binding=strong]")
    end
  end
end
