class Myc::Backend::Llvm::Backend < Myc::Backend::AbstractBackend
  def name
    "LLVM"
  end

  def self.version_string
    "LLVM #{LibLLVM::VERSION}"
  end

  def new_builder : AbstractBuilder
    layout = Layout.new(common_options.target || Target.from_triple(LLVM.default_target_triple))
    Builder.new(self, layout, common_options.final ? LLVM::CodeGenOptLevel::Aggressive : LLVM::CodeGenOptLevel::Default)
  end

  def obj(mod : Mod, header_mod : Mod, output : String)
    b = build(mod, header_mod)

    Myc.measure("backend:llvmobj") do
      if data.options["llvm-bitcode-obj"]?
        # LLVMWriteBitcodeToFile returns 0 on success
        unless b.llvm_mod.write_bitcode_to_file(output) == 0
          raise "WriteBitcode failed for #{output}"
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
    build_mod(mod, header_mod, new_builder).as(Builder).tap do |builder|
      builder.verify unless ENV["MYC_VERIFY"]? == "0"

      Myc.measure("backend:llvmopt") do
        mode = if common_options.final
                 # with bitcode the linker runs the rest of the pipeline
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
