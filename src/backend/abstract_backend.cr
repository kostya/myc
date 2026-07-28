abstract class Myc::Backend::AbstractBackend
  record CommonOptions, target : Target?, final : Bool

  abstract def name
  abstract def dump(mod : Mod, header_mod : Mod, output : String)
  abstract def obj(mod : Mod, header_mod : Mod, output : String)
  abstract def new_builder : AbstractBuilder

  def self.version_string
    "Abstract"
  end

  CC = ENV["CC"]? || ENV["cc"]? || "cc"

  getter data : Cli::Data
  getter common_options : CommonOptions
  property typer : Typer

  def initialize(@data)
    @common_options = parse_common_options
    @typer = Typer.new
  end

  def run
    case data.mode
    in .compile?
      target = _compile(target_for_compile)
      puts "compiled to #{target}"
    in .run?       then _run
    in .obj?       then _obj
    in .dump?      then _dump
    in .format?    then _format
    in .merge?     then _merge(STDOUT)
    in .explain?   then _explain
    in .undefined? then raise data.error("unknown mode #{data.mode}")
    end
  rescue ex : Error
    show_error(ex)
    exit(1)
  end

  protected def resolve_inputs(files : Array(String)) : Array(String)
    files.map { |f| resolve_input(f) }
  end

  protected def resolve_input(input : String) : String
    raise data.error("input not found `#{input}`") unless File.exists?(input)
    raise data.error("input not file `#{input}`") unless File.file?(input)

    unless filename_source?(input)
      raise data.error("unexpected file `#{input}`")
    end

    input
  end

  protected def parse_files(files : Array(String)) : Array({Mod, Source::Dom})
    files.map do |input|
      Myc.measure("load:parse") do
        src = File.read(input)
        tokens = Source::Tokenizer.new(src, input).parse
        parser = Source::Parser.new(input, tokens)
        parser.parse
        mod = Mod.new(File.basename(input, ext), input, typer)
        {mod, parser.dom}
      end
    end
  end

  protected def run_phases(parsed : Array({Mod, Source::Dom})) : Array(Mod)
    collector = Mod::TypeCollector.new(typer)
    Myc.measure("load:collect_types") do
      parsed.each { |mod, dom| collector.collect(mod, dom) }
    end

    Myc.measure("load:fill_types") do
      parsed.each do |mod, dom|
        filler = Mod::TypeFiller.new(typer, mod)
        filler.fill(dom)
      end
    end

    Myc.measure("load:check_types") do
      collector.duplicates.each do |(name, dup_mod, dup_type)|
        first_type = @typer.map[name]
        unless first_type.structural_eq?(dup_type)
          raise Error::ErrorLoc.new("type `#{name}` defined differently across modules (#{first_type.loc.filename}, #{dup_type.loc.filename})", dup_type.loc)
        else
          td = dup_mod.type_defs[name]
          td.type = first_type
        end
      end
    end

    Myc.measure("load:load_mods") do
      parsed.each do |mod, dom|
        loader = Mod::Loader.new(dom, mod.filename, typer, mod)
        loader.load
      end
    end

    Myc.measure("load:validate") do
      parsed.each { |mod, _| mod.validate! }
    end

    parsed.map(&.first)
  end

  protected def load_all(files : Array(String)) : Tuple(Array(Mod), Mod)
    myc_files = resolve_inputs(files)
    parsed = parse_files(myc_files)
    mods = run_phases(parsed)
    header_mod = build_header_module(mods)
    if save_result = ENV["MYC_SAVE_HEADER_MOD"]?
      File.open(save_result, "w") { |f| IO.copy(Mod::Saver.new(header_mod).save.serialize, f) }
    end

    inline_cross_module(mods, header_mod) unless ENV["MYC_DISABLE_INLINER"]? == "1"
    {mods, header_mod}
  end

  protected def load_single(input : String) : Tuple(Mod, Mod)
    mods, header = load_all([input])
    {mods.first, header}
  end

  protected def _compile(target : String)
    source_files = data.values.select { |f| filename_source?(f) }
    obj_files = data.values.select { |f| filename_object?(f) }

    objs = [] of String

    if source_files.any?
      mods, header = load_all(source_files)
      mods.each do |mod|
        obj_file = object_for(mod.filename)
        run_obj(mod, header, obj_file)
        objs << obj_file
      end
    end

    objs.concat(obj_files)
    raise data.error("nothing to compile") if objs.empty?

    linker(objs, target)
    target
  end

  protected def _run
    output = new_tmp_path("myc", "run")
    _compile(output)
    run_cmd(output, data.unparsed_argv, check_status: false, catch_stdout: ENV["MYC_SPEC"]? == "1")
  end

  protected def _obj
    input, output = if data.values.size == 1
                      {data.values[0], object_for(data.values[0])}
                    elsif data.values.size == 2
                      {data.values[0], data.values[1]}
                    else
                      raise data.error("obj require 2 files input and output")
                    end

    mod, header = load_single(input)
    run_obj(mod, header, output)
    puts "generated #{output}"
  end

  protected def _dump
    if data.values.size == 1
      input = data.values.first
      output = new_tmp_path("myc", "dump")
      mod, header = load_single(input)
      run_dump(mod, header, output)
      puts File.read(output)
    elsif data.values.size > 1
      mods, header = load_all(data.values)

      puts "-" * 50 + " dump for auto-generated header.myc " + "-" * 50
      output = new_tmp_path("myc", "dump")
      run_dump(header, header, output)
      puts File.read(output)
      puts

      mods.each_with_index do |mod, index|
        output = new_tmp_path("myc", "dump")
        run_dump(mod, header, output)
        puts "-" * 50 + " dump for #{mod.filename} " + "-" * 50

        puts File.read(output)
        puts
      end
    else
      raise data.error("dump empty")
    end
  end

  protected def _format
    files = data.values.flat_map do |path|
      if File.directory?(path)
        Dir.glob("#{path}/**/*#{ext}")
      elsif File.file?(path)
        [path]
      else
        [] of String
      end
    end

    files.each do |input|
      begin
        print "format #{input} "
        myc_files = resolve_inputs([input])
        parsed = parse_files(myc_files)
        _, dom = parsed.first
        File.open(input, "w") { |f| IO.copy(dom.serialize, f) }
        puts "ok!".colorize(:green)
      rescue ex : Error
        puts "error! (#{ex.message})".colorize(:red)
      end
    end
  end

  def _merge(io : IO)
    files = data.values.select { |f| filename_source?(f) }
    raise data.error("nothing to merge") if files.empty?
    mods, _ = load_all(files)
    mod = Mod.new("summary", "/tmp/summary", typer)
    Myc.measure("merge:collect") { mods.each { |m| mod.merge!(m, false) } }
    Myc.measure("merge:clean") { mod.clean_unused_types_and_globals }
    dom = Myc.measure("merge:save") { Mod::Saver.new(mod).save }
    Myc.measure("merge:serialize") { IO.copy(dom.serialize, io) }
  end

  protected def _explain
    if data.values.size == 1
      input = data.values.first
      mod, header = load_single(input)
      IO.copy(_lint(mod, header), STDOUT)
    elsif data.values.size > 1
      mods, header = load_all(data.values)

      STDOUT.puts "-" * 50 + " explain for auto-generated header.myc " + "-" * 50
      IO.copy(_lint(header, header), STDOUT)
      STDOUT.puts

      mods.each_with_index do |mod, index|
        STDOUT.puts "-" * 50 + " explain for #{mod.filename} " + "-" * 50
        IO.copy(_lint(mod, header), STDOUT)
        STDOUT.puts
      end
    else
      raise data.error("dump empty")
    end
  end

  private def _lint(mod : Mod, header : Mod) : IO
    linter = Linter::Backend.new(data)
    linter.typer = typer
    builder = linter.build_mod(mod, header, linter.new_builder).as(Linter::Builder)
    Mod::Saver.new(mod, builder.notes).save.serialize
  end

  protected def run_obj(mod : Mod, header_mod : Mod, output : String)
    ensure_dir(output)
    obj(mod, header_mod, output)
  end

  protected def run_dump(mod : Mod, header_mod : Mod, output : String)
    ensure_dir(output)
    dump(mod, header_mod, output)
  end

  protected def target_for_compile
    if data.values.size == 0
      raise data.error("nothing to compile")
    end

    last = data.values.last
    if filename_source?(last) || filename_object?(last)
      if (data.values.size == 1) && data.stdin_filename.nil?
        return File.basename(data.values.first, ext)
      else
        return "a.out"
      end
    end

    data.values.last
  end

  protected def build_mod(mod : Mod, header_mod : Mod, builder : AbstractBuilder) : AbstractBuilder
    Myc.measure("mod:build") do
      mod.finalize_enums(builder.layout)
      header_mod.finalize_enums(builder.layout) if header_mod != mod

      mod.func_defs.each do |name, func_def|
        builder.func_register(name, func_def)
      end

      header_mod.func_defs.each do |name, func_def|
        unless mod.func_defs.has_key?(name)
          builder.func_register(name, func_def)
        end
      end

      mod.global_defs.each_value do |global|
        builder.global_register(mod, global)
      end

      header_mod.global_defs.each_value do |global|
        unless mod.global_defs.has_key?(global.name)
          builder.global_register(header_mod, global)
        end
      end

      mod.func_defs.each do |_, func_def|
        if func_def.body
          builder.new_func(func_def, header_mod).build
        end
      end

      builder
    end
  end

  protected def linker(objs : Array(String), output : String)
    ensure_dir(output)
    Myc.measure("linker") do
      if link_flags = ENV["MYC_LINKER_FLAGS"]?
        objs += link_flags.split(" ").reject(&.blank?)
      end

      run_cmd(CC, objs + ["-lm", "-o", output])
    end
  end

  protected def show_error(error : Error)
    error.print(STDOUT)
  end

  protected def object_for(input, obj_ext = "o")
    base_name = File.basename(input, ext)
    output = Path[input].parent / "#{base_name}.#{obj_ext}"
    output.to_s
  end

  protected def ensure_dir(file)
    Dir.mkdir_p(File.dirname(file))
  end

  def self.new_tmp_path(prefix = "", temp_ext = "")
    bytes = Bytes.new(10)
    Random::Secure.random_bytes(bytes)
    tmp_name = bytes.hexstring
    File.join(Dir.tempdir, "#{prefix}_#{tmp_name}.#{temp_ext}")
  end

  def new_tmp_path(prefix = "", temp_ext = "", add_to_cleanup = true)
    path = self.class.new_tmp_path(prefix, temp_ext)
    data.files_to_cleanup << path if add_to_cleanup
    path
  end

  def run_cmd(cmd : String, args : Array(String), check_status = true, catch_stdout = false) : String?
    if ENV["MYC_VERBOSE"]? == "1"
      puts "--- '#{cmd} #{args.join(" ")}' ---"
    end

    res = if catch_stdout
            io = IO::Memory.new
            Process.run(cmd,
              args: args,
              input: Process::Redirect::Inherit,
              output: io,
              error: Process::Redirect::Inherit)
            io.to_s
          else
            Process.run(cmd,
              args: args,
              input: Process::Redirect::Inherit,
              output: Process::Redirect::Inherit,
              error: Process::Redirect::Inherit)
            nil
          end

    if check_status && ($?.exit_code != 0)
      raise Error::Cmd.new("Command `#{cmd}` failed with status #{$?.exit_code}", cmd, args)
    end

    res
  rescue ex
    raise Error::Cmd.new(ex.message, cmd, args)
  end

  private def parse_common_options : CommonOptions
    target = if target_str = data.options["target"]?
               Target.from_triple(target_str)
             end

    final = !!data.options["final"]?
    CommonOptions.new(target: target, final: final)
  end

  protected def detect_native_target : Target
    arch = {% if flag?(:arm64) || flag?(:aarch64) %}
             Target::Arch::Arm64
           {% elsif flag?(:x86_64) || flag?(:amd64) %}
             Target::Arch::X86_64
           {% elsif flag?(:i386) %}
             Target::Arch::X86
           {% else %}
             Target::Arch::Unknown
           {% end %}
    Target.new(arch)
  end

  def debug_flags : String
    String.build do |s|
      s << '('
      s << (common_options.final ? "final" : "default")
      if target = common_options.target
        s << ", "
        s << target.arch.to_s
      end
      s << ')'
    end
  end

  protected def ext
    EXT
  end

  protected def filename_source?(filename : String) : Bool
    filename.ends_with?(ext)
  end

  protected def filename_object?(filename : String) : Bool
    filename.ends_with?(".o")
  end

  private def inline_cross_module(mods : Array(Mod), header_mod : Mod)
    Myc.measure("mod:inliner") do
      mods.each do |mod|
        Myc::Mod::Inliner.new(mod, header_mod).inline!
      end

      if save_result = ENV["MYC_SAVE_INLINER_RESULT"]?
        File.open(save_result, "w") { |f| IO.copy(Mod::Saver.new(mods.first).save.serialize, f) }
      end
    end
  end

  private def build_header_module(mods : Array(Mod)) : Mod
    raise data.error("no targets in build_header_module") if mods.size == 0
    return mods[0] if mods.size == 1

    Myc.measure("mod:header") do
      header = Mod.new("__header__", "/tmp/__header__", typer)
      mods.each { |mod| header.merge!(mod, true) }

      header.global_defs.each do |name, global_def|
        if global_def.initial_keyword
          decl = global_def.dup
          decl.initial_keyword = false
          decl.initial_values = [] of Source::Token::Value
          header.global_defs[name] = decl
        end
      end

      header.func_defs.each do |name, func_def|
        if func_def.body
          if func_def.inline_stats.can_inline && !func_def.inline_stats.private_dependency
          else
            decl = func_def.dup
            decl.body = nil
            header.func_defs[name] = decl
          end
        end
      end

      header
    end
  end
end
