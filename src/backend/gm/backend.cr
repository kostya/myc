class Myc::Backend::GM::Backend < Myc::Backend::AbstractBackend
  def name
    "GM"
  end

  # The release of the cppgm library in use. The library loads on the first
  # call, so a build without it still states the backend.
  def self.version_string
    "GM v#{NativeAPI.version}"
  rescue
    "GM (cppgm library not found)"
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
        builder.compile(output, optimization_level)
      end
    ensure
      builder.close
    end
  end

  # The cppgm optimization level: O3 with --final, O0 with --debug, else O1.
  private def optimization_level : Int32
    return 3 if common_options.final
    common_options.debug ? 0 : 1
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
