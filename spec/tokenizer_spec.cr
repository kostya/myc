require "./spec_helper"

context "Myc::Source::Tokenizer" do
  it "PUSH number" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:1:7]"
      PUSH 1
    SRC
  end

  it "PUSH space" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:4, V:1:9]"
        PUSH 1
    SRC
  end

  it "some" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:1:7, O:RET:11]"
      PUSH 1
      RET
    SRC
  end

  it "double quotes" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"hello\":7]"
      PUSH "hello"
    SRC
  end

  it "single quotes" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"hello\":7]"
      PUSH 'hello'
    SRC
  end

  it "string :asdf" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"asdf\":7]"
      PUSH :asdf
    SRC
  end

  it "string" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"lba#@$\":7]"
      PUSH "lba#@$"
    SRC
  end

  it "float number" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:3.14:7]"
      PUSH 3.14
    SRC
  end

  it "float exp" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:15000000000.0:7]"
      PUSH 1.5e10
    SRC
  end

  it "neg" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:-42:7]"
      PUSH -42
    SRC
  end

  it "hex number" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:4096:7, O:PUSH:16, V:255:21, O:PUSH:28, V:43981:33]"
      PUSH 0x1000
      PUSH 0xFF
      PUSH 0xABCD
    SRC
  end

  it "true" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:true:7]"
      PUSH true
    SRC
  end

  it "false" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:false:7]"
      PUSH false
    SRC
  end

  it "string without anything" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"my_var\":7]"
      PUSH my_var
    SRC
  end

  it "commeng" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:1:7, O:RET:23]"
      PUSH 1
      # comment
      RET
    SRC
  end

  it "comment" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:1:7]"
      PUSH 1 # comment
    SRC
  end

  it "comment ;" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:1:7, O:RET:33]"
      PUSH 1
      ; this is a comment
      RET
    SRC
  end

  it "comment ;" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:1:7]"
      PUSH 1 ; comment
    SRC
  end

  it "empty strings" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:1:7, O:RET:14]"
      PUSH 1



      RET
    SRC
  end

  it "tabs" do
    tokenize("\tPUSH\t1\t").inspect.should eq "[O:PUSH:1, V:1:6]"
  end

  it "CRLF" do
    tokenize("PUSH 1\r\nRET").inspect.should eq "[O:PUSH:0, V:1:5, O:RET:8]"
  end

  it "func" do
    src = <<-SRC
    FUNC main
    RETURN TYPE i32
    ARGS TYPE i32 TYPE i32
    BODY
      PARAM 0
      PARAM 1
      BINARY add
      RET
    ENDFUNC
    SRC

    tokenize(src).inspect.should eq <<-EQ
    [O:FUNC:0, V:"main":5, O:RETURN:10, O:TYPE:17, V:"i32":22, O:ARGS:26, O:TYPE:31, V:"i32":36, O:TYPE:40, V:"i32":45, O:BODY:49, O:PARAM:56, V:0:62, O:PARAM:66, V:1:72, O:BINARY:76, V:"add":83, O:RET:89, O:ENDFUNC:93]
    EQ
  end

  it "error bad string" do
    expect_raises(Myc::Error::ErrorLoc, /string not ended/) do
      tokenize(%(PUSH "hello))
    end
  end

  it "error unexpected@" do
    expect_raises(Myc::Error::ErrorLoc, /unexpected symbol/) do
      tokenize("PUSH @value")
    end
  end

  it "error @" do
    expect_raises(Myc::Error::ErrorLoc, /unexpected symbol/) do
      tokenize("@")
    end
  end

  it "error number with word" do
    expect_raises(Myc::Error::ErrorLoc, /expected separator after number/) do
      tokenize("PUSH 1bla")
    end
  end

  it "error: overflow" do
    expect_raises(Myc::Error::ErrorLoc, /number constant is too big/) do
      tokenize("PUSH 100000000000000000000000")
    end
  end

  it "error -word" do
    expect_raises(Myc::Error::ErrorLoc, /unexpected symbol '-'/) do
      tokenize("PUSH -myvar")
    end
  end

  it "empty" do
    tokenize("").inspect.should eq "[]"
  end

  it "spaces" do
    tokenize("   \n  \t  ").inspect.should eq "[]"
  end

  it "comments" do
    tokenize("# just a comment\n").inspect.should eq "[]"
  end

  it "no values" do
    tokenize(<<-SRC).inspect.should eq "[O:RET:2]"
      RET
    SRC
  end

  it "many values" do
    tokenize(<<-SRC).inspect.should eq "[O:CALL:2, V:\"printf\":7, V:1:14]"
      CALL printf 1
    SRC
  end

  it "escape" do
    tokenize(%(PUSH "hello\\nworld")).inspect.should eq %([O:PUSH:0, V:"hello\\nworld":5])
  end

  it "hard string" do
    tokenize(%(PUSH 'it\\'s')).inspect.should eq %([O:PUSH:0, V:"it's":5])
  end

  it "unknown opcode" do
    tokenize(<<-SRC).inspect.should eq "[OU:HAHHAHAHA:2, V:1:12]"
      HAHHAHAHA 1
    SRC
  end

  it "parse float, was bug" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:1.0:7]"
      PUSH 1.0
    SRC
  end

  it "parse edge number" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:-9223372036854775808:7, O:PUSH:30, V:9223372036854775807:35]"
      PUSH -9223372036854775808
      PUSH 9223372036854775807
    SRC
  end

  it "parse edge u64" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:18446744073709551615:7]"
      PUSH 18446744073709551615
    SRC
  end

  it "PUSH special float" do
    tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:-Infinity:7, O:PUSH:14, V:Infinity:19, O:PUSH:26, V:NaN:31, O:PUSH:38, V:NaN:43]"
      PUSH -Inf
      PUSH +Inf
      PUSH +nan
      PUSH -NAN
    SRC
  end

  context "escaping" do
    it "PUSH escaping symbols" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"ሴ\":7]"
      PUSH "\\u1234"
    SRC
    end

    it "escapes \\n" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\n\":7]"
      PUSH "\\n"
    SRC
    end

    it "escapes \\t" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\t\":7]"
      PUSH "\\t"
    SRC
    end

    it "escapes \\r" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\r\":7]"
      PUSH "\\r"
    SRC
    end

    it "escapes \\f" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\f\":7]"
      PUSH "\\f"
    SRC
    end

    it "escapes \\v" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\v\":7]"
      PUSH "\\v"
    SRC
    end

    it "escapes \\a" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\a\":7]"
      PUSH "\\a"
    SRC
    end

    it "escapes \\b" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\b\":7]"
      PUSH "\\b"
    SRC
    end

    it "escapes \\s to space" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\" \":7]"
      PUSH "\\s"
    SRC
    end

    it "escapes \\e to ESC" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\e\":7]"
      PUSH "\\e"
    SRC
    end

    it "escapes \\\\" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\\\\":7]"
      PUSH "\\\\"
    SRC
    end

    it "escapes \\\"" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\\"\":7]"
      PUSH "\\""
    SRC
    end

    it "escapes \\' inside single quotes" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"'\":7]"
      PUSH '\\''
    SRC
    end

    it "escapes \\u0041 to A" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"A\":7]"
      PUSH "\\u0041"
    SRC
    end

    it "escapes \\uFFFF" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\uFFFF\":7]"
      PUSH "\\uFFFF"
    SRC
    end

    it "escapes \\u0000 to NUL" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\u0000\":7]"
      PUSH "\\u0000"
    SRC
    end

    it "escapes \\u{41} to A" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"A\":7]"
      PUSH "\\u{41}"
    SRC
    end

    it "escapes \\u{1F52E} to crystal ball" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"🔮\":7]"
      PUSH "\\u{1F52E}"
    SRC
    end

    it "escapes \\u{10FFFF}" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\u{10FFFF}\":7]"
      PUSH "\\u{10FFFF}"
    SRC
    end

    it "escapes \\x41 to A" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"A\":7]"
      PUSH "\\x41"
    SRC
    end

    it "escapes \\xFF" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"ÿ\":7]"
      PUSH "\\xFF"
    SRC
    end

    it "escapes \\x{41} to A" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"A\":7]"
      PUSH "\\x{41}"
    SRC
    end

    it "escapes \\x{1F52E}" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"🔮\":7]"
      PUSH "\\x{1F52E}"
    SRC
    end

    it "escapes \\o101 to A" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"A\":7]"
      PUSH "\\o101"
    SRC
    end

    it "escapes \\o{101} to A" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"A\":7]"
      PUSH "\\o{101}"
    SRC
    end

    it "escapes \\o{777} to ǿ" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"ǿ\":7]"
      PUSH "\\o{777}"
    SRC
    end

    it "escapes \\0 to NUL" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\u0000\":7]"
      PUSH "\\0"
    SRC
    end

    it "escapes \\101 to A" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"A\":7]"
      PUSH "\\101"
    SRC
    end

    it "escapes \\377 to 0xFF" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"ÿ\":7]"
      PUSH "\\377"
    SRC
    end

    it "escapes \\cA to SOH" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\u0001\":7]"
      PUSH "\\cA"
    SRC
    end

    it "escapes \\c-a to SOH" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\u0001\":7]"
      PUSH "\\c-a"
    SRC
    end

    it "escapes \\c@" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\u0000\":7]"
      PUSH "\\c@"
    SRC
    end

    it "escapes \\c?" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\u007F\":7]"
      PUSH "\\c?"
    SRC
    end

    it "escapes \\c[" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\e\":7]"
      PUSH "\\c["
    SRC
    end

    it "escapes mixed sequences" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"a\\tb\\n\":7]"
      PUSH "a\\tb\\n"
    SRC
    end

    it "escapes adjacent escapes" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"\\u0001\\u0002\":7]"
      PUSH "\\u0001\\u0002"
    SRC
    end

    it "does not escape ordinary backslash-free string" do
      tokenize(<<-SRC).inspect.should eq "[O:PUSH:2, V:\"hello\":7]"
      PUSH "hello"
    SRC
    end

    it "raises on unterminated string" do
      expect_raises(Myc::Error::ErrorLoc, /string not ended/) do
        tokenize(<<-SRC)
        PUSH "abc
      SRC
      end
    end

    it "raises on undefined escape" do
      expect_raises(Myc::Error::ErrorLoc, /undefined escape char/) do
        tokenize(<<-SRC)
        PUSH "\\q"
      SRC
      end
    end

    it "raises on bad hex in \\x" do
      expect_raises(Myc::Error::ErrorLoc, /invalid hex digit/) do
        tokenize(<<-SRC)
        PUSH "\\xZZ"
      SRC
      end
    end

    it "raises on bad hex in \\u" do
      expect_raises(Myc::Error::ErrorLoc, /invalid hex digit/) do
        tokenize(<<-SRC)
        PUSH "\\uZZZZ"
      SRC
      end
    end

    it "raises on bad hex in \\u{}" do
      expect_raises(Myc::Error::ErrorLoc, /invalid hex digit/) do
        tokenize(<<-SRC)
        PUSH "\\u{ZZ}"
      SRC
      end
    end

    it "raises on empty \\u{}" do
      expect_raises(Myc::Error::ErrorLoc, /empty/) do
        tokenize(<<-SRC)
        PUSH "\\u{}"
      SRC
      end
    end

    it "raises on empty \\x{}" do
      expect_raises(Myc::Error::ErrorLoc, /empty/) do
        tokenize(<<-SRC)
        PUSH "\\x{}"
      SRC
      end
    end

    it "raises on unterminated \\u{...}" do
      expect_raises(Myc::Error::ErrorLoc, /unterminated/) do
        tokenize(<<-SRC)
        PUSH "\\u{41
      SRC
      end
    end

    it "raises on unterminated \\x{...}" do
      expect_raises(Myc::Error::ErrorLoc, /unterminated/) do
        tokenize(<<-SRC)
        PUSH "\\x{41
      SRC
      end
    end

    it "raises on codepoint too large in \\u{}" do
      expect_raises(Myc::Error::ErrorLoc, /invalid codepoint/) do
        tokenize(<<-SRC)
        PUSH "\\u{110000}"
      SRC
      end
    end

    it "raises on trailing backslash" do
      expect_raises(Myc::Error::ErrorLoc, /unexpected end of input/) do
        tokenize(<<-SRC)
        PUSH "abc\\
      SRC
      end
    end

    it "raises on \\c without control char" do
      expect_raises(Myc::Error::ErrorLoc, /unexpected end of input/) do
        tokenize(<<-SRC)
        PUSH "\\c
      SRC
      end
    end

    it "raises on invalid control char" do
      expect_raises(Myc::Error::ErrorLoc, /invalid control character/) do
        tokenize(<<-SRC)
        PUSH "\\c!"
      SRC
      end
    end
  end
end
