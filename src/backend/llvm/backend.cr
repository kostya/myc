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
      b.generate_obj(output)
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
                 "default<O3>"
               else
                 "mem2reg,sccp,dce,simplifycfg"
               end
        builder.optimize!(mode)
      end
    end
  end
end
