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
