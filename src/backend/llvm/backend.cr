class Myc::Backend::Llvm::Backend < Myc::Backend::AbstractBackend
  def name
    "LLVM"
  end

  def self.version_string
    "LLVM #{LibLLVM::VERSION}"
  end

  def new_builder : AbstractBuilder
    layout = Layout.new(common_options.target || Target.from_triple(LLVM.default_target_triple))
    opt = if common_options.final
            LLVM::CodeGenOptLevel::Aggressive
          elsif common_options.debug
            LLVM::CodeGenOptLevel::None
          else
            LLVM::CodeGenOptLevel::Default
          end
    Builder.new(self, layout, opt)
  end

  def obj(mod : Mod, header_mod : Mod, output : String)
    b = build(mod, header_mod)

    Myc.measure("backend:llvmobj") do
      if data.options["llvm-bitcode-obj"]?
        unless b.llvm_mod.write_bitcode_to_file(output) == 0
          raise data.error("WriteBitcode failed for #{output}")
        end
      else
        b.generate_obj(output)
      end
    end
  end

  def dump(mod : Mod, header_mod : Mod, output : String)
    b = build(mod, header_mod)

    Myc.measure("backend:llvmll") do
      b.generate_ll(output)
    end
  end

  def build(mod : Mod, header_mod : Mod) : Builder
    cfg = gc_config_from_cli
    sp = gc_safepoints_for?(mod, header_mod, cfg)
    layout = Layout.new(common_options.target || Target.from_triple(LLVM.default_target_triple))
    opt = if common_options.final && !sp
            LLVM::CodeGenOptLevel::Aggressive
          elsif sp
            # SelectionDAG (FastISel is off on the target machine). IR stays
            # at O0 via default<O0> and optnone on functions.
            LLVM::CodeGenOptLevel::None
          elsif common_options.debug
            LLVM::CodeGenOptLevel::None
          else
            LLVM::CodeGenOptLevel::Default
          end
    b = Builder.new(self, layout, opt, disable_fast_isel: sp)
    cfg.enabled = sp
    b.gc_config = cfg
    build_mod(mod, header_mod, b).as(Builder).tap do |builder|
      builder.verify unless ENV["MYC_VERIFY"]? == "0"

      Myc.measure("backend:llvmopt") do
        mode = if builder.gc_safepoints
                 # mem2reg / GVN / stack coloring reuse a rooted alloca after
                 # its last IR use while the root hook still holds the address,
                 # or forward a pre-CALL pointer SSA across a collecting CALL.
                 "default<O0>"
               elsif common_options.final
                 data.options["llvm-bitcode-obj"]? ? "lto-pre-link<O3>" : "default<O3>"
               elsif common_options.debug
                 "default<O0>"
               else
                 "mem2reg,sccp,dce,simplifycfg"
               end
        builder.optimize!(mode)
      end
    end
  end
end
