require "./spec_helper"

describe Myc::Backend::Layout do
  it "keeps nested field padding and tail padding consistent with size" do
    type = spec_find_type("struct<u8, struct<u8, i64>, u16>").as(Myc::Type::StructType)
    layout = Myc::Backend::Layout.new(Myc::Backend::Target.new(:x86_64, :linux))
    # Query late fields before asking for size; repeat in a different order.
    layout.field_offset(type, 2_u64).should eq 24_u64
    layout.size_of(type).should eq 32_u64
    layout.field_offset(type, 1_u64).should eq 8_u64
    layout.field_offset(type, 0_u64).should eq 0_u64
    layout.field_offset(type, 2_u64).should eq 24_u64
  end

  it "preserves explicit packing and over-alignment for each field" do
    [{1_u64, [0_u64, 1_u64, 9_u64], 11_u64},
     {16_u64, [0_u64, 16_u64, 32_u64], 48_u64}].each do |alignment, offsets, size|
      type = spec_find_type("struct<u8, i64, u16>").as(Myc::Type::StructType)
      type.explicit_alignment = alignment
      layout = Myc::Backend::Layout.new(Myc::Backend::Target.new(:x86_64, :linux))
      layout.size_of(type).should eq size
      offsets.each_with_index { |offset, i| layout.field_offset(type, i.to_u64).should eq offset }
      layout.alignment_of(type).should eq alignment
    end
  end

  it "keeps offsets specific to the target data layout" do
    type = spec_find_type("struct<u8, ptr<i32>, u16>").as(Myc::Type::StructType)
    [{Myc::Backend::Target::Arch::X86_64, 8_u64, 16_u64, 24_u64}, {Myc::Backend::Target::Arch::X86, 4_u64, 8_u64, 12_u64}].each do |arch, pointer, last, size|
      layout = Myc::Backend::Layout.new(Myc::Backend::Target.new(arch, :linux))
      layout.field_offset(type, 1_u64).should eq pointer
      layout.field_offset(type, 2_u64).should eq last
      layout.size_of(type).should eq size
    end
  end
end
