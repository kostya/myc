lib LibLLVM
  fun const_insert_value = LLVMConstInsertValue(aggregate : ValueRef, element : ValueRef, index : UInt) : ValueRef
end

class Myc::Backend::Llvm::Builder < Myc::Backend::AbstractBuilder
  getter context : LLVM::Context
  getter target_machine : LLVM::TargetMachine
  getter type_translator : TypeTranslator
  getter llvm_mod : LLVM::Module

  getter string_constants = Hash(String, LLVM::Value).new
  getter func_links = Hash(String, FuncLink).new
  getter global_links = Hash(String, Value).new
  getter codegen_opt_level : LLVM::CodeGenOptLevel

  def initialize(@backend, @layout, @codegen_opt_level = LLVM::CodeGenOptLevel::None)
    super(@backend, @layout)

    @context = LLVM::Context.new(LibLLVM.create_context, false)
    @target_machine = create_target_machine(@layout.target.triple)
    @type_translator = TypeTranslator.new(@context, @layout)

    @llvm_mod = @context.new_module(AbstractBackend.tmp_name)
    @llvm_mod.target = @target_machine.triple
    @llvm_mod.data_layout = @target_machine.data_layout
  end

  private def create_target_machine(triple : String)
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
    machine
  end

  def llvm_type(type : Type) : LLVM::Type
    type_translator.translate(type)
  end

  def verify
    Myc.measure(:verify) do
      @llvm_mod.verify
    end
  end

  def func_register(name : String, type_fn : Type::Fn)
    func_link(name, type_fn)
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
        init = init_val(global.initial_values, global.type, mod, Location.new(mod.filename, global.node.offset))
        var.initializer = llvm_val(init)
      else
        var.initializer = _llvm_type.undef
      end
    else
      var.linkage = LLVM::Linkage::External
    end

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
    when InitValue::NullPtr
      llvm_type(init.type).null
    when InitValue::GlobalRef
      global_links[init.name].bbval.as(BBVal).llvm
    when InitValue::FnRef
      llvm_func = func_link(init.name, init.type.as(Type::Fn)).llvm_function
      LLVM::Value.new(llvm_func.to_unsafe)
    when InitValue::StructInit
      fields = init.fields.map { |f| llvm_val(f) }

      s = context.const_struct(fields)
      p s
      s
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
    Myc.measure(:llvm_generate_ll) do
      Myc.debug(:compile) { "Generate LL #{filename}" }
      File.open(filename, "w") { |file| llvm_mod.to_s(file) }
    end
  rescue ex
    puts "GenerateLL failed with #{ex.inspect}"
  end

  def generate_obj(filename)
    Myc.measure(:llvm_generate_obj) do
      Myc.debug(:compile) { "Generate Obj #{filename}" }
      target_machine.emit_obj_to_file llvm_mod, filename
    end
  rescue ex
    puts "GenerateObj failed with #{ex.inspect}"
  end

  def optimize!(mode = "O2")
    Myc.measure(:llvm_generate_obj) do
      LLVM::PassBuilderOptions.new do |options|
        LLVM.run_passes(llvm_mod, ENV["LLVM_PASSES"]? || "default<#{mode}>", target_machine, options)
      end
    end
  end

  def init_value(ival : InitValue) : Value
    Value.new(BBVal.new(llvm_val(ival)), ival.type, Value::MM::Val, Value::PP::Primitive.new)
  end

  def find_global(name : String) : Value?
    global_links[name]?
  end

  def new_func(func_def : Mod::FuncDef) : AbstractFunc
    Func.new(self, func_def)
  end
end
