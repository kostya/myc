require "./spec_helper"

# Backend-specific contracts run in the GM CI cell, where cppgm is installed.
# Other backend cells deliberately build and run without this dependency.
if (ENV["BACKEND"]? || "gm").split(',').any? { |backend| backend.strip.downcase.starts_with?("gm") }
  describe "GM native library" do
    it "owns independent modules and tolerates repeated close after GC" do
      first = Myc::Backend::GM::NativeModule.new(0_u32)
      second = Myc::Backend::GM::NativeModule.new(0_u32)
      begin
        Myc::Backend::GM::NativeAPI.symbol(first.pointer, "first", 5).should eq 0_u32
        Myc::Backend::GM::NativeAPI.symbol(second.pointer, "second", 6).should eq 0_u32
        GC.collect
        Myc::Backend::GM::NativeAPI.symbol(first.pointer, "another", 7).should eq 1_u32
      ensure
        first.close
        first.close
        second.close
      end
      first.pointer.null?.should be_true
    end

    it "constructs, validates and compiles directly through the shared records" do
      native = Myc::Backend::GM::NativeModule.new(0_u32)
      begin
        m = native.pointer
        symbol = Myc::Backend::GM::NativeAPI.symbol(m, "answer", 6)
        signature = Myc::Backend::GM::NativeAPI.signature(m, Myc::Backend::GM.ir_type(Myc::Backend::GM::IRType::I32), Pointer(UInt64).null, 0, 0)
        Myc::Backend::GM::NativeAPI.function(m, symbol, signature, 2, 1).should eq 1
        counts = Myc::Backend::GM::LibGM::BodyCounts.new(instructions: 1, literals: 1, blocks: 1)
        buffers = Myc::Backend::GM::LibGM::BodyBuffers.new
        Myc::Backend::GM::NativeAPI.reserve(m, symbol, pointerof(counts), pointerof(buffers)).should eq 1
        buffers.layout.as(UInt32*)[0] = 0_u32
        buffers.literals.as(Myc::Backend::GM::LibGM::Literal*)[0] = Myc::Backend::GM::LibGM::Literal.new(low: 42_u64)
        buffers.instructions.as(Myc::Backend::GM::LibGM::Instruction*)[0] = Myc::Backend::GM::LibGM::Instruction.new(
          op: Myc::Backend::GM::IROp::Return.value, result: Myc::Backend::GM::NO_ID,
          type: Myc::Backend::GM.ir_type(Myc::Backend::GM::IRType::I32),
          ops: StaticArray[Myc::Backend::GM.ir_value(Myc::Backend::GM::IRKind::Integer), Myc::Backend::GM::LibGM::Value.new, Myc::Backend::GM::LibGM::Value.new])
        Myc::Backend::GM::NativeAPI.commit(m, symbol, pointerof(counts), 0).should eq 1
        Myc::Backend::GM::NativeAPI.validate(m).should eq 1
        Myc::Backend::GM::NativeAPI.compile(m, 0, 0).should eq 1
        size = Myc::Backend::GM::NativeAPI.object_size(m)
        size.should be > 4_u64
        Slice.new(Myc::Backend::GM::NativeAPI.object_data(m), 4).to_a.should eq [0x7f_u8, 0x45_u8, 0x4c_u8, 0x46_u8]
      ensure
        native.close
      end
    end
  end
end
