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
    raise data.error("GM backend is only supported on x86-64 targets, current: #{layout.target.inspect}") unless layout.target.arch.x86_64?
    Builder.new(self, layout)
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
            run_cmd(path, ["-O#{opt_level}", "-S", "-emit-lowir", tmp, "-o", output])
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
