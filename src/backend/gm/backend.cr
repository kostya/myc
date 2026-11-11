class Myc::Backend::GM::Backend < Myc::Backend::AbstractBackend
  GM = ENV["GM"]? || Process.find_executable("cppgm++") ||
       File.join(File.dirname(__FILE__), "..", "..", "..", "plugins", "cppgm-extended", "dev", "cppgm++")

  def name
    "GM"
  end

  def self.version_string
    "GM"
  end

  def new_builder : AbstractBuilder
    layout = new_layout
    raise data.error("GM backend is only supported on x86-64 targets, current: #{layout.target.inspect}") unless layout.target.arch.x86_64?
    Builder.new(self, layout)
  end

  def obj(mod : Mod, header_mod : Mod, output : String)
    tmp = new_tmp_path("myc", "lowir")
    build(mod, header_mod, tmp)

    Myc.measure("backend:lowir2obj") do
      args = ["-c", tmp, "-o", output]

      if common_options.final
        args.unshift "-O3"
      elsif common_options.debug
      else
        args.unshift "-O1"
      end

      run_cmd(GM, args)
    end
  end

  def dump(mod : Mod, header_mod : Mod, output : String)
    build(mod, header_mod, output)
  end

  def build(mod : Mod, header_mod : Mod, output : String) : Builder
    build_mod(mod, header_mod, new_builder).as(Builder).tap do |builder|
      builder.save(output)
    end
  end
end
