class Myc::Backend::GM::Backend < Myc::Backend::AbstractBackend
  def name
    "GM"
  end

  def self.version_string
    "GM v#{NativeAPI.version}"
  rescue
    "GM (cppgm library not found)"
  end

  def new_builder : AbstractBuilder
    layout = new_layout
    ir_target = IRTarget.from_target(layout.target) || raise data.error("GM does not support target #{layout.target.triple}")
    Builder.new(self, layout, ir_target)
  end

  def obj(mod : Mod, header_mod : Mod, output : String)
    builder = new_builder.as(Builder)
    begin
      build_mod(mod, header_mod, builder)
      Myc.measure("backend:compile") do
        builder.compile(output, optimization_level)
      end
    ensure
      builder.close
    end
  end

  def dump(mod : Mod, header_mod : Mod, output : String)
    builder = new_builder.as(Builder)
    begin
      build_mod(mod, header_mod, builder)

      opt_level = optimization_level
      if (opt_level > 0)
        if (path = find_cppgm_path)
          tmp = new_tmp_path("myc", "lowir")
          Myc.measure("backend:dump") { builder.save(tmp) }
          Myc.measure("backend:dumpopt") do
            run_cmd(path, ["--target=#{builder.target.triple}", "-O#{opt_level}", "-S", "-emit-lowir", tmp, "-o", output])
          end
        else
          STDERR.puts "Warning, cppgm not found, dump shown without cppgm optimizations".colorize(:yellow)
          Myc.measure("backend:dump") { builder.save(output) }
        end
      else
        Myc.measure("backend:dump") { builder.save(output) }
      end
    ensure
      builder.close
    end
  end

  protected def additional_linker_flags : Array(String)
    target = output_target
    return [] of String unless target.os.darwin?
    ["-arch", target.arch.arm64? ? "arm64" : "x86_64"]
  end

  protected def new_layout : Layout
    Layout.new(output_target)
  end

  private def output_target : Target
    native = detect_native_target
    target = common_options.target || return native
    if target.os.unknown? && target.original_triple.try { |triple| !triple.includes?('-') }
      return Target.new(target.arch, native.os)
    end
    target
  end

  private def optimization_level : Int32
    return 3 if common_options.final
    common_options.debug ? 0 : 1
  end

  private def find_cppgm_path : String?
    if path = Process.find_executable("cppgm")
      return path
    end

    path = ENV["CPPGM"]? || File.join(File.dirname(__FILE__), "..", "..", "..", "plugins", "cppgm", "bin", "cppgm")
    if File.file?(path)
      return path
    end
  end
end
