require "spec"
require "../src/myc"

ENV["MYC_SPEC"] = "1"

class Myc::Backend::AbstractBackend
  def spec_run
    _run
  end
end

def tokenize(src)
  Myc::Source::Tokenizer.new(src, "/tmp/1").parse
end

def parse(src)
  tokens = Myc::Source::Tokenizer.new(src, "/tmp/1").parse
  parser = Myc::Source::Parser.new("/tmp/1", tokens)
  parser.parse

  dom = parser.dom

  String.build { |s| Myc::Source::Serialize.new(dom, s).serialize }.strip
end

def validate(src)
  tokens = Myc::Source::Tokenizer.new(src, "/tmp/1").parse
  parser = Myc::Source::Parser.new("/tmp/1", tokens)
  parser.parse

  dom = parser.dom

  l = Myc::Mod::Loader.new(dom, "/tmp/1")
  l.mod.validate!
  l.load

  s = Myc::Mod::Saver.new(l.mod)
  dom2 = s.save

  String.build { |s| Myc::Source::Serialize.new(dom2, s).serialize }.strip
end

def spec_typer
  mod = Myc::Mod.new("1", "/tmp/1")
  mod.typer
end

def spec_find_type(name : String) : Myc::Type
  spec_typer.find(name, Myc::Location.new("/tmp/1", 0))
end

abstract struct Myc::Source::Token
  def inspect(io)
    case t = self
    when Opcode
      io << "O:#{t.code.to_s}:#{offset}"
    when Arg
      io << "V:#{t.v.inspect}:#{offset}"
    when OpcodeUnknown
      io << "OU:#{t.name}:#{offset}"
    else
      raise "unexpected #{t.class}"
    end
  end
end

Spec.after_suite do
  Myc.print_timers
end

class Examples
  enum Kind
    C
    MYC
  end

  record Example,
    filename : String,
    rel_filename : String,
    kind : Kind,
    error : Bool,
    pending : Bool,
    expect : String,
    categories : Array(String),
    multi_modules : Array(String) do
    def register(backend : String, release : Bool)
      test_name = if kind.c?
                    "[#{backend}#{release ? 1 : 0}] [cat #{rel_filename}] (crystal src/cli/mycc.cr #{rel_filename} --backend #{backend.downcase} d)"
                  else
                    "[#{backend}#{release ? 1 : 0}] [cat #{rel_filename}] (crystal src/cli/#{backend.downcase}.cr #{rel_filename} d)"
                  end

      if @pending
        pending(test_name) { }
      elsif error
        it(test_name) do
          ex = expect_raises(Myc::Error, "") do
            run(backend, release)
          end
          s = String.build { |io| ex.print(io) }
          s.gsub(/\e\[[\d;]*m/, "").should contain(expect)
        end
      else
        it(test_name) do
          run(backend, release).should eq expect
        end
      end
    end

    def run(backend : String, release : Bool)
      p filename if ENV["FILENAME"]? == "1"
      data = Myc::Cli::Data.new
      data.mode = :run
      data.values << filename

      if release
        data.options["release"] = ""
      end

      unless multi_modules.empty?
        data.values += multi_modules
      end

      runner = if kind.c?
                 data.options["backend"] = backend
                 Myc::Backend::Mycc::Backend.new(data)
               else
                 case backend
                 when "LLVM"
                   Myc::Backend::Llvm::Backend.new(data)
                 when "C"
                   Myc::Backend::C::Backend.new(data)
                 when "QBE"
                   Myc::Backend::QBE::Backend.new(data)
                 else
                   raise "unknown runner #{backend}"
                 end
               end

      runner.spec_run.try &.strip
    end
  end

  getter examples = Array(Example).new

  def initialize
    t = Time.local
    dirs = Set(String).new
    basedir = File.join(File.dirname(__FILE__), "examples")

    keywords = nil
    if filter = ENV["FILTER"]?
      keywords = filter.split(",").map(&.strip).reject(&.blank?)
      keywords = nil if keywords.empty?
    end

    all_files = Dir.glob(File.join(basedir, "**", "*.{myc,c}"))
    main_files = all_files.reject { |f| f =~ /\.\d+\.(err\.)?(myc|c)$/ }

    main_files.each do |f|
      if keywords
        next unless keywords.any? { |k| f.includes?(k) }
      end

      kind = f.ends_with?(".myc") ? Kind::MYC : Kind::C
      error = f.ends_with?(".err.myc") || f.ends_with?(".err.c")
      basename = File.basename(f)
      dir = File.dirname(f)
      dirs << dir
      pend = f.includes?("/p-")
      expect_file = f.sub(/\.(err\.)?(myc|c)$/, ".txt")

      content = if pend
                  ""
                else
                  unless File.exists?(expect_file)
                    "-- not found file #{expect_file} --"
                  else
                    File.read(expect_file)
                  end
                end

      categories = f.sub(basedir + "/", "").split("/")[0..-2]

      multi_modules = find_part_files(f)

      examples << Example.new(
        f,
        "spec/examples/" + f.sub(basedir + "/", ""),
        kind,
        error,
        pend,
        content.strip,
        categories,
        multi_modules
      )
    end

    puts "Found #{examples.size} examples in #{(Time.local - t).to_f.round(5)}s"
  end

  private def find_part_files(main_file : String) : Array(String)
    base = main_file.sub(/\.(err\.)?(myc|c)$/, "")

    if main_file.includes?(".err.")
      pattern = "#{base}.*.err.{myc,c}"
    else
      pattern = "#{base}.*.{myc,c}"
    end

    Dir.glob(pattern).select { |pf| pf =~ /\.\d+\.(err\.)?(myc|c)$/ }.sort
  end

  def run
    all_modes = Array(Tuple(String, Bool)).new

    backends = %w{LLVM QBE C}

    backends.each do |backend|
      {true, false}.each do |mode|
        all_modes << {backend, mode}
      end
    end

    backend_filter = (ENV["BACKEND"]? || "").split(",").map(&.strip).reject(&.blank?).map(&.downcase)
    filtered_modes = if backend_filter.empty?
                       all_modes
                     else
                       res = Array(Tuple(String, Bool)).new
                       backend_filter.each do |filter|
                         modes = all_modes.dup
                         modes.reject! { |b, m| m } if filter == "0"
                         modes.reject! { |b, m| !m } if filter == "1"
                         backends.each do |backend|
                           modes.select! { |b, m| b == backend } if filter == backend.downcase
                           modes.select! { |b, m| b == backend && !m } if filter == "#{backend.downcase}0"
                           modes.select! { |b, m| b == backend && m } if filter == "#{backend.downcase}1"
                         end
                         res += modes
                       end
                       res.uniq!
                       res
                     end

    puts "Test modes: #{filtered_modes.inspect}"
    filtered_modes.each do |backend, mode|
      examples.each do |example|
        example.register(backend, mode)
      end
    end
  end
end

require "../src/backend/llvm/all"
require "../src/backend/qbe/all"
require "../src/backend/c/all"
require "../src/backend/mycc/all"
