require "./spec_helper"

context "Merge" do
  it "simple merge" do
    src1 = <<-'_____________________________src'
    FUNC :main BODY CALL :bla INSPECT ENDFUNC
    _____________________________src

    src2 = <<-'_____________________________src'
    FUNC :bla RETURN TYPE :i32 BODY PUSH 42 RET ENDFUNC
    _____________________________src

    res = <<-'_____________________________src'
    FUNC :main
      BODY
        PUSH 42
        SLOT :__bla_0_0_ret
        SLOT :__bla_0_0_ret
        INSPECT
    ENDFUNC

    FUNC :bla
      RETURN
        TYPE :i32
      BODY
        PUSH 42
        RET
    ENDFUNC
    _____________________________src

    merge(src1, src2).should eq res
  end

  it "bug" do
    src1 = <<-'_____________________________src'
    STRUCT :A
      TYPE :i32
      TYPE :B
    ENDSTRUCT

    ENUM :B
      TAG
        SKIP
      VARIANT :e
        TYPE :u32
      VARIANT :f
        TYPE "flat<u8, 4>"
    ENDENUM

    FUNC :main BODY LOCAL :x :A STACK :drop ENDFUNC
    _____________________________src

    src2 = <<-'_____________________________src'
    STRUCT :A
      TYPE :i32
      TYPE :C
    ENDSTRUCT

    ENUM :C
      TAG
        SKIP
      VARIANT :e
        TYPE :u32
      VARIANT :f
        TYPE "flat<u8, 4>"
    ENDENUM
    _____________________________src

    res = <<-'_____________________________src'
    STRUCT :A
      TYPE :i32
      TYPE :B
    ENDSTRUCT

    ENUM :B
      TAG
        SKIP
      VARIANT :e
        TYPE :u32
      VARIANT :f
        TYPE "flat<u8, 4>"
    ENDENUM

    FUNC :main
      BODY
        LOCAL :x :A
        STACK :drop
    ENDFUNC
    _____________________________src

    merge(src1, src2).should eq res
  end
end
