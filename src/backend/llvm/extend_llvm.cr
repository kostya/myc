lib LibLLVM
  fun build_array_alloca = LLVMBuildArrayAlloca(BuilderRef, element_type : TypeRef, size : ValueRef, name : Char*) : ValueRef
end

class LLVM::Builder
  def build_array_alloca(elem_type : LLVM::Type, size : LLVM::Value, name : String = "") : LLVM::Value
    v = LibLLVM.build_array_alloca(self.to_unsafe, elem_type, size, name)
    LLVM::Value.new(v)
  end
end
