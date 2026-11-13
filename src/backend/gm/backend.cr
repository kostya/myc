class Myc::Backend::GM::Backend < Myc::Backend::AbstractBackend
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
    builder = new_builder.as(Builder)
    begin
      build_mod(mod, header_mod, builder)
      Myc.measure("backend:lowir2obj") do
        level = common_options.final ? 3 : (common_options.debug ? 0 : 1)
        builder.compile(output, level)
      end
    ensure
      builder.close
    end
  end

  def dump(mod : Mod, header_mod : Mod, output : String)
    builder = new_builder.as(Builder)
    begin
      build_mod(mod, header_mod, builder)
      builder.save(output)
    ensure
      builder.close
    end
  end
end
