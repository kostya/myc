class Myc::Backend::Llvm::Builder < Myc::Backend::AbstractBuilder
  getter context : LLVM::Context
  getter target_machine : LLVM::TargetMachine
  getter type_translator : TypeTranslator
  getter llvm_mod : LLVM::Module

  getter string_constants = Hash(String, LLVM::Value).new
  getter func_links = Hash(String, FuncLink).new
  getter global_links = Hash(String, Value).new
  getter codegen_opt_level : LLVM::CodeGenOptLevel

  def initialize(@backend, @layout, @codegen_opt_level = LLVM::CodeGenOptLevel::None, *, disable_fast_isel = false)
    super(@backend, @layout)

    @context = LLVM::Context.new(LibLLVM.create_context, false)
    @target_machine = create_target_machine(@layout.target.triple, disable_fast_isel)
    @type_translator = TypeTranslator.new(@context, @layout, @backend.typer)

    @llvm_mod = @context.new_module("main")
    @llvm_mod.target = @target_machine.triple
    @llvm_mod.data_layout = @target_machine.data_layout
  end

  private def create_target_machine(triple : String, disable_fast_isel : Bool)
    case triple
    when /arm64|aarch64/i then LLVM.init_aarch64
    when /arm/i           then LLVM.init_arm
    when /wasm/i          then LLVM.init_webassembly
    when /avr/i           then LLVM.init_avr
    else                       LLVM.init_x86
    end

    llvm_target = LLVM::Target.from_triple(triple)
    machine = llvm_target.create_target_machine(triple,
      cpu: "",
      features: "",
      opt_level: @codegen_opt_level,
      code_model: LLVM::CodeModel::Default,
      reloc: LLVM::RelocMode::PIC).not_nil!
    machine.enable_global_isel = false
    # FastISel crashes on gc.statepoint (parseRegisterLiveOutMask).
    LibLLVM.set_target_machine_fast_isel(machine, 0) if disable_fast_isel
    machine
  end

  @valist_llvm_type : LLVM::Type?

  def valist_llvm_type : LLVM::Type
    @valist_llvm_type ||= begin
      @context.struct([@context.int32, @context.int32,
                       @context.pointer, @context.pointer], "valist")
    end
  end

  def llvm_type(type : Type) : LLVM::Type
    type_translator.translate(type)
  end

  def verify
    Myc.measure("backend:llvmver") do
      @llvm_mod.verify
    end
  end

  def func_register(name : String, func_def : Mod::FuncDef)
    func_link(name, func_def.type_fn)
  end

  def func_link(name : String, type_fn : Type::Fn) : FuncLink
    @func_links.put_if_absent(name) { FuncLink.new(name, type_fn, @llvm_mod, @type_translator) }
  end

  def global_register(mod : Mod, global : Mod::GlobalDef)
    _llvm_type = llvm_type(global.type)
    var = llvm_mod.globals.add(_llvm_type, global.name)

    if global.initial_keyword
      var.linkage = LLVM::Linkage::Internal
      if global.initial_values.size > 0
        vp = AbstractBuilder::ValuesParser.new(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
        init = vp.parse
        var.initializer = llvm_val(init)
      else
        var.initializer = _llvm_type.undef
      end
    else
      var.linkage = LLVM::Linkage::External
    end

    var.linkage = global.private_flag ? LLVM::Linkage::Internal : LLVM::Linkage::External
    var.global_constant = global.constant

    if global_links[global.name]?
      raise global.node.error("Already defined global #{global.name}: #{global.type}", mod.filename)
    end
    g = Value.new(BBVal.new(var), global.type, Value::MM::Ref, global.constant ? Value::PP::GlobalConstant.new(global.name) : Value::PP::Global.new(global.name))
    global_links[global.name] = g
  end

  def llvm_val(init : InitValue) : LLVM::Value
    case init
    when InitValue::Intval
      llvm_type(init.type).const_int(init.val)
    when InitValue::Boolval
      llvm_type(init.type).const_int(init.val ? 1 : 0)
    when InitValue::F32
      llvm_type(init.type).const_float(init.val)
    when InitValue::F64
      llvm_type(init.type).const_double(init.val)
    when InitValue::Str
      string_constant(init.str)
    when InitValue::Zero
      llvm_type(init.type).null
    when InitValue::GlobalRef
      global_links[init.name].bbval.as(BBVal).llvm
    when InitValue::FnRef
      llvm_func = func_link(init.name, init.type.as(Type::Fn)).llvm_function
      LLVM::Value.new(llvm_func.to_unsafe)
    when InitValue::StructInit
      fields = init.fields.map { |f| llvm_val(f) }
      llvm_type(init.type).const_struct(fields)
    when InitValue::FlatInit
      elem_type = llvm_type(init.type.as(Type::FlatType).target_type)
      elems = init.elements.map { |e| llvm_val(e) }
      elem_type.const_array(elems)
    when InitValue::FlatStr
      llvm_mod.context.const_bytes(init.str.to_slice)
    else
      raise "unreachable"
    end
  end

  def string_constant(str : String) : LLVM::Value
    string_constants.put_if_absent(str) { make_global_string(str) }
  end

  private def make_global_string(str)
    name = "str"
    context = llvm_mod.context
    str_const = context.const_string(str)
    str_type = str_const.type
    global = llvm_mod.globals.add(str_type, name)
    global.linkage = LLVM::Linkage::Private
    global.global_constant = true
    global.initializer = str_const
    global
  end

  def generate_ll(filename)
    Myc.debug(:compile) { "Generate LL #{filename}" }
    File.open(filename, "w") { |file| llvm_mod.to_s(file) }
  rescue ex
    puts "GenerateLL failed with #{ex.inspect}"
  end

  def generate_obj(filename)
    Myc.debug(:compile) { "Generate Obj #{filename}" }
    target_machine.emit_obj_to_file llvm_mod, filename
    mark_llvm_stackmaps_writable(filename) if gc_safepoints
  rescue ex
    puts "GenerateObj failed with #{ex.inspect}"
  end

  # LLVM emits .llvm_stackmaps as SHF_ALLOC only. Function-address
  # relocs in that read-only section become DT_TEXTREL in a PIE.
  # SHF_WRITE makes them ordinary data relocs.
  private def mark_llvm_stackmaps_writable(filename : String) : Nil
    File.open(filename, "r+") do |f|
      ident = Bytes.new(16)
      return if f.read(ident) != 16
      return unless ident[0] == 0x7f && ident[1] == 'E'.ord && ident[2] == 'L'.ord && ident[3] == 'F'.ord
      return unless ident[4] == 2 # ELFCLASS64
      return unless ident[5] == 1 # ELFDATA2LSB

      f.seek(40)
      shoff = f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
      f.seek(58)
      shentsize = f.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      shnum = f.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      shstrndx = f.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      return if shoff == 0 || shentsize != 64 || shnum == 0 || shstrndx >= shnum

      f.seek(shoff + shstrndx.to_u64 * 64)
      f.read_bytes(UInt32, IO::ByteFormat::LittleEndian) # sh_name
      f.read_bytes(UInt32, IO::ByteFormat::LittleEndian) # sh_type
      f.read_bytes(UInt64, IO::ByteFormat::LittleEndian) # sh_flags
      f.read_bytes(UInt64, IO::ByteFormat::LittleEndian) # sh_addr
      str_off = f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
      str_size = f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
      return if str_size == 0 || str_size > 1_048_576

      f.seek(str_off)
      names = Bytes.new(str_size)
      return if f.read(names) != str_size.to_i

      i = 0_u16
      while i < shnum
        f.seek(shoff + i.to_u64 * 64)
        name_off = f.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
        f.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
        flags_pos = f.pos
        flags = f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
        if elf_section_name?(names, name_off, ".llvm_stackmaps")
          unless flags.bits_set?(0x1_u64) # SHF_WRITE
            f.seek(flags_pos)
            f.write_bytes(flags | 0x1_u64, IO::ByteFormat::LittleEndian)
          end
          return
        end
        i = i &+ 1
      end
    end
  rescue
    # Truncated object or no ELF: leave LLVM's section flags alone.
  end

  private def elf_section_name?(names : Bytes, off : UInt32, want : String) : Bool
    start = off.to_i
    return false if start < 0 || start >= names.size
    bytes = want.to_slice
    return false if start + bytes.size >= names.size
    i = 0
    while i < bytes.size
      return false if names[start + i] != bytes[i]
      i += 1
    end
    names[start + bytes.size] == 0
  end

  def optimize!(mode = "O2")
    LLVM::PassBuilderOptions.new do |options|
      pass = ENV["MYC_LLVM_PASSES"]? || mode
      puts "llvm passes: #{pass}" if ENV["MYC_VERBOSE"]? == "1"
      LLVM.run_passes(llvm_mod, pass, target_machine, options)
    end
  end

  def init_value(ival : InitValue) : Value
    Value.new(BBVal.new(llvm_val(ival)), ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  def find_global(name : String) : Value?
    global_links[name]?
  end

  def new_func(func_def : Mod::FuncDef, header_mod : Mod) : AbstractFunc
    Func.new(self, func_def, header_mod)
  end
end
