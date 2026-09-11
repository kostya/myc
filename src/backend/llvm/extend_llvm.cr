lib LibLLVM
  fun build_array_alloca = LLVMBuildArrayAlloca(BuilderRef, element_type : TypeRef, size : ValueRef, name : Char*) : ValueRef
  fun const_named_struct = LLVMConstNamedStruct(t : TypeRef, constant_vals : ValueRef*, count : UInt) : ValueRef
end

class LLVM::Builder
  def build_array_alloca(elem_type : LLVM::Type, size : LLVM::Value, name : String = "") : LLVM::Value
    v = LibLLVM.build_array_alloca(self.to_unsafe, elem_type, size, name)
    LLVM::Value.new(v)
  end
end

struct LLVM::Type
  def const_struct(values : Array(LLVM::Value))
    Value.new LibLLVM.const_named_struct(self, (values.to_unsafe.as(LibLLVM::ValueRef*)), values.size)
  end
end

lib LibLLVM
  fun build_indirect_br = LLVMBuildIndirectBr(
    builder : BuilderRef,
    addr : ValueRef,
    num_destinations : UInt,
  ) : ValueRef

  fun add_destination = LLVMAddDestination(
    indirect_br : ValueRef,
    dest : BasicBlockRef,
  ) : Void

  fun block_address = LLVMBlockAddress(
    f : ValueRef,
    bb : BasicBlockRef,
  ) : ValueRef
end

class LLVM::Builder
  def indirect_br(address : LLVM::Value, destinations : Array(LLVM::BasicBlock)) : LLVM::Value
    v = LibLLVM.build_indirect_br(
      self.to_unsafe,
      address,
      destinations.size
    )

    destinations.each do |dest|
      LibLLVM.add_destination(v, dest.to_unsafe)
    end

    LLVM::Value.new(v)
  end
end

struct LLVM::BasicBlock
  def address : LLVM::Value
    parent = LibLLVM.get_basic_block_parent(self.to_unsafe)
    v = LibLLVM.block_address(parent, self.to_unsafe)
    LLVM::Value.new(v)
  end
end
