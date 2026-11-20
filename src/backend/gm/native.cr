module Myc::Backend::GM
  ABI_VERSION     = 4_u32
  ARM_ABI_VERSION = 5_u32

  NO_ID = UInt32::MAX

  enum IRTarget : UInt32
    Linux        = 0
    MacOS        = 1
    AArch64Linux = 5
    AArch64MacOS = 6

    def self.from_target(target : Target) : self?
      case {target.arch, target.os}
      when {Target::Arch::X86_64, Target::OS::Linux}  then Linux
      when {Target::Arch::X86_64, Target::OS::Darwin} then MacOS
      when {Target::Arch::Arm64, Target::OS::Linux}   then AArch64Linux
      when {Target::Arch::Arm64, Target::OS::Darwin}  then AArch64MacOS
      end
    end

    def abi_version : UInt32
      self == AArch64Linux || self == AArch64MacOS ? ARM_ABI_VERSION : ABI_VERSION
    end

    def triple : String
      case self
      in Linux        then "x86_64-linux-gnu"
      in MacOS        then "x86_64-apple-darwin"
      in AArch64Linux then "aarch64-linux-gnu"
      in AArch64MacOS then "arm64-apple-macos11"
      end
    end
  end

  enum IRArity : UInt32
    Fixed    = 0
    Variadic = 1
  end

  enum IRBinding : UInt32
    Internal = 1
    Strong   = 2
  end

  enum IRStorage : UInt32
    Default  = 0
    ReadOnly = 1
  end

  enum IRFunctionForm : UInt32
    Declaration = 0
    Definition  = 1
  end

  enum IRGlobalForm : UInt32
    Definition  = 0
    Declaration = 1
  end

  enum IRCodeForm : UInt32
    Fixed = 0
  end

  enum IRDataKind : UInt32
    Scalar  = 0
    Address = 1
    Zero    = 2
  end

  enum IRKey : UInt32
    NoInline = 20
  end

  @[Flags]
  enum IRFlag : UInt8
    Signature =  2
    Typed     = 64
  end

  enum IRType : UInt8
    Void =  0
    I1   =  1
    I8   =  2
    U8   =  3
    I16  =  4
    U16  =  5
    I32  =  6
    U32  =  7
    I64  =  8
    I128 =  9
    F32  = 10
    F64  = 11
    F80  = 12
    Ptr  = 13
  end

  enum IROp : UInt8
    Copy       =  1
    Addr       =  3
    Load       =  4
    Index      =  6
    Unary      =  7
    Binary     =  8
    Compare    =  9
    Select     = 10
    Convert    = 11
    VaArg      = 16
    StackAlloc = 17
    Call       = 21
    Store      = 25
    VaStart    = 29
    CopyObject = 32
    Throw      = 40
    Jump       = 42
    Branch     = 43
    Switch     = 44
    Return     = 46
  end

  enum IRUnary : UInt8
    Neg                = 0
    BitNot             = 2
    CountTrailingZeros = 4
    CountLeadingZeros  = 5
    Sqrt               = 6
    CountOnes          = 7
  end

  enum IRBinary : UInt8
    Add  =  0
    Sub  =  1
    Mul  =  2
    Div  =  3
    Mod  =  4
    UDiv =  5
    UMod =  6
    And  =  7
    Or   =  8
    Xor  =  9
    Shl  = 10
    Shr  = 11
    UShr = 12
  end

  enum IRCmp : UInt8
    Eq  = 0
    Ne  = 1
    Lt  = 2
    Le  = 3
    Gt  = 4
    Ge  = 5
    Ult = 6
    Ule = 7
    Ugt = 8
    Uge = 9
  end

  enum IRConvert : UInt8
    SExt    = 0
    ZExt    = 1
    Trunc   = 2
    SIToFP  = 3
    UIToFP  = 4
    FPToSI  = 5
    FPToUI  = 6
    FPExt   = 7
    FPTrunc = 8
  end

  enum IRKind : UInt8
    None    = 0
    Temp    = 1
    Slot    = 2
    Symbol  = 3
    Block   = 4
    Integer = 5
    Float   = 6
  end

  lib LibGM
    type Module = Void

    struct Value
      kind : UInt8
      float_kind : UInt8
      reserved : UInt16
      index : UInt32
    end

    struct Literal
      low : UInt64
      high : UInt64
    end

    struct Instruction
      op : UInt8
      sub : UInt8
      flags : UInt8
      order : UInt8
      result : UInt32
      next : UInt32
      location : UInt32
      type : UInt64
      ops : Value[3]
      extra_first : UInt32
      extra_count : UInt32
      immediate : Int64
    end

    struct Slot
      name : UInt32
      kind : UInt8
      reserved : UInt8
      index : UInt16
      type : UInt64
    end

    struct BodyCounts
      instructions : UInt32
      operands : UInt32
      literals : UInt32
      slots : UInt32
      blocks : UInt32
    end

    struct BodyBuffers
      instructions : UInt8*
      operands : UInt8*
      literals : UInt8*
      slots : UInt8*
      layout : UInt8*
      capacity : BodyCounts
    end

    struct DataItem
      type : UInt64
      bits : Literal
      amount : Int64
      symbol : UInt32
      kind : UInt32
    end

    struct Field
      offset : UInt64
      type : UInt64
      count : UInt64
    end

    {% if flag?(:gm_static) %}
      fun abi_version = cppgm_lowir_abi_version : UInt32
      fun version = cppgm_lowir_version : UInt8*
      fun create = cppgm_lowir_create(version : UInt32, target : UInt32) : Module*
      fun destroy = cppgm_lowir_destroy(mod : Module*)
      fun error = cppgm_lowir_error(mod : Module*) : UInt8*
      fun symbol = cppgm_lowir_symbol(mod : Module*, name : UInt8*, length : UInt32) : UInt32
      fun signature = cppgm_lowir_signature(mod : Module*, result : UInt64, params : UInt64*, count : UInt32, variadic : UInt32) : UInt32
      fun record = cppgm_lowir_record(mod : Module*, bytes : UInt64, alignment : UInt32, fields : Field*, count : UInt32) : UInt64
      fun symbol_fact = cppgm_lowir_symbol_fact(mod : Module*, symbol : UInt32, key : UInt32, value : UInt32) : Int32
      fun function = cppgm_lowir_function(mod : Module*, symbol : UInt32, signature : UInt32, binding : UInt32, definition : UInt32) : Int32
      fun global = cppgm_lowir_global(mod : Module*, symbol : UInt32, type : UInt64, binding : UInt32, storage : UInt32, items : DataItem*, count : UInt32, declaration : UInt32) : Int32
      fun reserve = cppgm_lowir_body_reserve(mod : Module*, symbol : UInt32, minimum : BodyCounts*, buffers : BodyBuffers*) : Int32
      fun commit = cppgm_lowir_body_commit(mod : Module*, symbol : UInt32, counts : BodyCounts*, temp_count : UInt32) : Int32
      fun validate = cppgm_lowir_validate(mod : Module*) : Int32
      fun write = cppgm_lowir_write(mod : Module*, path : UInt8*) : Int32
      fun compile = cppgm_lowir_compile(mod : Module*, level : UInt32, pic : UInt32) : Int32
      fun object_data = cppgm_lowir_object_data(mod : Module*) : UInt8*
      fun object_size = cppgm_lowir_object_size(mod : Module*) : UInt64
    {% end %}
  end

  class NativeModule
    getter pointer : LibGM::Module*

    def initialize(target : IRTarget)
      abi = target.abi_version
      @pointer = NativeAPI.create(abi, target)
      if @pointer.null?
        raise "cannot create GM LowIR module for #{target}: this target needs LowIR ABI v#{abi}, " \
              "cppgm #{NativeAPI.version} provides v#{NativeAPI.abi_version}"
      end
    end

    def close
      unless @pointer.null?
        NativeAPI.destroy(@pointer)
        @pointer = Pointer(LibGM::Module).null
      end
    end

    def finalize
      close
    end
  end

  def self.ir_value(kind : IRKind, id : UInt32 = 0_u32) : LibGM::Value
    LibGM::Value.new(kind: kind.value, index: id)
  end

  def self.ir_type(kind : IRType) : UInt64
    kind.value.to_u64
  end
end
