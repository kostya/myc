require "fileutils"

unless File.directory?("../plugins/LangArena")
  `git clone https://github.com/kostya/LangArena.git ../plugins/LangArena`
  Dir.chdir("../plugins/LangArena/c") do
    `make deps`
    `make -j prod`
  end
end

ROOT = "../plugins/LangArena/c"
SOURCES = Dir.glob("#{ROOT}/**/*.c")
SOURCES.reject! { |f| f.include?("c/deps/") || f.include?("c/target/") }
INCLUDES = [ROOT, "#{ROOT}/src", "#{ROOT}/deps/yyjson/src", "#{ROOT}/deps/base64/include", "/opt/homebrew/include"]

def measure
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t).to_f
end

class Run
  attr_reader :name, :cmd, :build_dir, :output, :version

  def initialize(name:, cmd:, build_dir:, output:, version:)
    @name = name
    @cmd = cmd
    @build_dir = build_dir
    @output = output
    @version = version

    if File.directory?(build_dir)
      FileUtils.rm_rf(build_dir)
    end
    FileUtils.mkdir_p(build_dir)

    @link_time = 0.0
    @build_obj_time = 0.0
  end

  def link(objs)
    @link_time += measure do
      link_deps = "#{ROOT}/target/deps/prod/libbase64.o #{ROOT}/target/deps/prod/yyjson.o -pthread -lpcre2-8 -L/opt/homebrew/lib"
      c = "cc #{objs.join(" ")} #{link_deps} -lm -o #{@output}"
      `#{c}`
    end
  end

  def build_all
    v = `#{version}`

    puts "--------------------- building (#{name}) #{v} -------------------------------"
    objs = []
    SOURCES.each do |source|
      obj = "#{build_dir}/#{File.basename(source)}.o"
      @build_obj_time += measure do
        build(source, obj)
      end
      objs << obj
    end

    puts "--------------------- linking (#{name}) #{v} -------------------------------"
    link(objs)
  end

  def build(source, out)
    raise "implement build"
  end

  def stats
    {
      build_obj_time: build_obj_time.round(6),
      link_time: link_time.round(6)
    }
  end

  def run
    c = "#{output} #{ROOT}/../run.js"
    res = `#{c}`
    puts res
  end
end

class Cc < Run
  def build(source, out)
    include_str = INCLUDES.map{ |i| "-I#{i}" }.join(" ")
    c = "#{cmd} #{include_str} #{source} -o #{out}"
    puts "execute: `#{c}`"
    `#{c}`
  end
end

class Myc < Run
  def build(source, out)
    include_str = INCLUDES.join(",")
    c = "MYCC_INCLUDE=#{include_str} #{cmd} #{source} #{out}"
    puts "execute: `#{c}`"
    `#{c}`
  end
end

runs = []

runs << Cc.new(
  name: "clang(-O3)",
  cmd: "clang -O3 -c",
  build_dir: "/tmp/myc_bench_la/clang",
  output: "./bin_la_clang",
  version: "clang --version",
)

runs << Cc.new(
  name: "gcc(-O3)",
  cmd: "gcc -O3 -c",
  build_dir: "/tmp/myc_bench_la/gcc",
  output: "./bin_la_gcc",
  version: "gcc --version",
)

runs << Cc.new(
  name: "cproc",
  cmd: "cproc -c",
  build_dir: "/tmp/myc_bench_la/cproc",
  output: "./bin_la_cproc",
  version: "cproc --version",
)

runs << Myc.new(
  name: "mycc(llvm, release)",
  cmd: "../mycc o --release --backend llvm",
  build_dir: "/tmp/myc_bench_la/mycc-llvm",
  output: "./bin_la_myc_llvm",
  version: "../myc-llvm --version",
)

runs << Myc.new(
  name: "mycc(qbe, release)",
  cmd: "../mycc o --release --backend qbe",
  build_dir: "/tmp/myc_bench_la/mycc-qbe",
  output: "./bin_la_myc_qbe",
  version: "../myc-qbe --version",
)

runs << Myc.new(
  name: "mycc(c, release, clang)",
  cmd: "CC=clang ../mycc o --release --backend c",
  build_dir: "/tmp/myc_bench_la/mycc-c-clang",
  output: "./bin_la_myc_c_clang",
  version: "../myc-c --version",
)

runs << Myc.new(
  name: "mycc(c, release, gcc)",
  cmd: "CC=gcc ../mycc o --release --backend c",
  build_dir: "/tmp/myc_bench_la/mycc-c-gcc",
  output: "./bin_la_myc_c_gcc",
  version: "../myc-c --version",
)

unless ENV["FILTER"].empty?
  runs.select! { |r| r.name.downcase.include?(ENV["FILTER"].downcase) }
end

runs.each do |run|
  run.build_all
end

p runs

runs.map do |run|
  [run.name, run.stats]
end
