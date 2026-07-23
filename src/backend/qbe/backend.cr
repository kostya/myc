class Myc::Backend::QBE::Backend < Myc::Backend::AbstractBackend
  QBE = ENV["QBE"]? || File.join(File.dirname(__FILE__), "..", "..", "..", "plugins", "qbe", "qbe")
  AS  = ENV["AS"]? || "as"

  def name
    "QBE"
  end

  def self.version_string
    "QBE fab6d40"
  end

  def new_builder : AbstractBuilder
    layout = Layout.new(common_options.target || detect_native_target)
    Builder.new(self, layout)
  end

  def obj(mod : Mod, header_mod : Mod, output : String)
    self.class.with_tempfile_path("myc", "ssa") do |tmp|
      build(mod, header_mod, tmp)

      self.class.with_tempfile_path("myc", "s") do |tmp2|
        Myc.measure("qbe_asm") do
          self.class.run_cmd(QBE, ["-o", tmp2, tmp])
        end
        Myc.measure("asm_obj") do
          self.class.run_cmd(AS, ["-c", tmp2, "-o", output])
        end
      end
    end
  end

  def dump(mod : Mod, header_mod : Mod, output : String)
    build(mod, header_mod, output)
  end

  def build(mod : Mod, header_mod : Mod, output : String) : Builder
    if common_options.final && ENV["MYC_SPEC"]? != "1"
      puts "--final option for QBE is skipped".colorize(:yellow)
    end

    build_mod(mod, header_mod).as(Builder).tap do |builder|
      builder.save(output)
    end
  end
end
