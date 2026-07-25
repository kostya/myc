class Myc::Backend::C::Backend < Myc::Backend::AbstractBackend
  def name
    "C"
  end

  def self.version_string
    "#{`#{CC} --version 2>/dev/null | head -n 1`.strip}"
  end

  def new_builder : AbstractBuilder
    layout = Layout.new(common_options.target || detect_native_target)
    Builder.new(self, layout)
  end

  def obj(mod : Mod, header_mod : Mod, output : String)
    tmp = new_tmp_path("myc", "c")

    build(mod, header_mod, tmp)
    args = ["-c",
            "-fno-strict-aliasing",
            "-Wno-main-return-type",
            "-Wno-pointer-sign",
            "-Wno-constant-conversion",
            "-Wno-format-security",
            "-Wno-incompatible-library-redeclaration",
            "-Wno-implicit-function-declaration",
            "-o", output,
            tmp]

    if common_options.final
      args << "-O3"
    else
      args << "-O1"
      args << "-fno-inline"
    end

    if c_flgs = ENV["MYC_C_FLAGS"]?
      args += c_flgs.split(",")
    end

    Myc.measure("backend:c2obj") do
      run_cmd(CC, args)
    end
  end

  def dump(mod : Mod, header_mod : Mod, output : String)
    build(mod, header_mod, output)
  end

  def build(mod : Mod, header_mod : Mod, output : String) : Builder
    build_mod(mod, header_mod).as(Builder).tap do |builder|
      builder.save(output)
    end
  end
end
