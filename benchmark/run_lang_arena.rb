require "fileutils"

unless File.directory?("../plugins/LangArena")
  `git clone https://github.com/kostya/LangArena.git ../plugins/LangArena`
  Dir.chdir("../plugins/LangArena/c") do
    `make deps`
    `make -j prod`
    f = File.read("./deps/yyjson/src/yyjson.h")
    f.gsub!(/^#\s*error\s+non\s+8-bit\s+char\s+is\s+not\s+supported.*$\n?/, '')
    File.write("./deps/yyjson/src/yyjson.h", f)
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

$exitst = 0

class Run
  attr_reader :name, :cmd, :build_dir, :output, :version, :env

  def initialize(name:, cmd:, build_dir:, output:, version:, env:)
    @name = name
    @cmd = cmd
    @build_dir = build_dir
    @output = output
    @version = version
    @env = env

    if File.directory?(build_dir)
      FileUtils.rm_rf(build_dir)
    end
    FileUtils.mkdir_p(build_dir)

    @link_time = 0.0
    @build_obj_time = 0.0
    @summary_mem = 0.0
    @summary_mem_cnt = 0
    @run_time = 0.0
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
        res = build(source, obj)
        if res =~ /MaxRSS\((\d+)\)KB/
          @summary_mem += $1.to_i
          @summary_mem_cnt += 1
        end
      end
      objs << obj
    end

    puts "--------------------- linking (#{name}) #{v} -------------------------------"
    File.delete(@output) rescue nil
    link(objs)
  end

  def build(source, out)
    raise "implement build"
  end

  def stats
    {
      build_obj_time: @build_obj_time.round(6),
      link_time: @link_time.round(6),
      avg_memory_mb: ((@summary_mem / @summary_mem_cnt) / 1024).round(6),
      mem_cnt: @summary_mem_cnt,
      run_time: @run_time,
    }
  end

  def run
    c = "#{output} #{ROOT}/../run.js"
    res = `#{c}`
    unless @summary_mem_cnt == 29
      $exitst = 1
      puts "Warning compiled only #{@summary_mem_cnt} from 29"
    end
    line = res.split("\n").find { |l| l.include?("Summary") }
    if line && line.include?("50, 50, ") && line =~ /Summary:\s*(\d+\.\d+)s/
      delta = $1.to_f
      @run_time = delta
      puts "OK in #{delta}"
    else
      $exitst = 1
      puts "ERROR #{line}"
    end
  end
end

class Cc < Run
  def build(source, out)
    include_str = INCLUDES.map{ |i| "-I#{i}" }.join(" ")
    c = "#{env} /usr/bin/time -f 'MaxRSS(%M)KB' 2>&1 #{cmd} #{include_str} #{source} -o #{out}"
    unless ENV["MYC_CI"] == "1"
      puts "execute: `#{c}`"
    end
    `#{c}`
  end
end

class Myc < Run
  def build(source, out)
    include_str = INCLUDES.join(",")
    c = "MYCC_INCLUDE=#{include_str} #{env} /usr/bin/time -f 'MaxRSS(%M)KB' 2>&1 #{cmd} #{source} #{out}"
    unless ENV["MYC_CI"] == "1"
      puts "execute: `#{c}`"
    end
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
  env: "",
)

runs << Cc.new(
  name: "clang(-O1)",
  cmd: "clang -O1 -c",
  build_dir: "/tmp/myc_bench_la/clang_o1",
  output: "./bin_la_clang_o1",
  version: "clang --version",
  env: "",
)

runs << Cc.new(
  name: "clang(-O0)",
  cmd: "clang -O0 -c",
  build_dir: "/tmp/myc_bench_la/clang_o0",
  output: "./bin_la_clang_o0",
  version: "clang --version",
  env: "",
)

runs << Cc.new(
  name: "gcc(-O3)",
  cmd: "gcc -O3 -c",
  build_dir: "/tmp/myc_bench_la/gcc",
  output: "./bin_la_gcc",
  version: "gcc --version",
  env: "",
)

runs << Cc.new(
  name: "cproc",
  cmd: "cproc -c",
  build_dir: "/tmp/myc_bench_la/cproc",
  output: "./bin_la_cproc",
  version: "cproc --version",
  env: "",
)

runs << Myc.new(
  name: "mycc(llvm)",
  cmd: "../mycc o --backend llvm",
  build_dir: "/tmp/myc_bench_la/mycc-llvm",
  output: "./bin_la_myc_llvm",
  version: "../mycc --backend llvm --version",
  env: "",
)

runs << Myc.new(
  name: "mycc(qbe)",
  cmd: "../mycc o --backend qbe",
  build_dir: "/tmp/myc_bench_la/mycc-qbe",
  output: "./bin_la_myc_qbe",
  version: "../mycc --backend qbe --version",
  env: "",
)

runs << Myc.new(
  name: "mycc(c, clang)",
  cmd: "../mycc o --backend c",
  build_dir: "/tmp/myc_bench_la/mycc-c-clang",
  output: "./bin_la_myc_c_clang",
  version: "../mycc --backend c --version",
  env: "CC=clang",
)

runs << Myc.new(
  name: "mycc(c, gcc)",
  cmd: "../mycc o --backend c",
  build_dir: "/tmp/myc_bench_la/mycc-c-gcc",
  output: "./bin_la_myc_c_gcc",
  version: "../mycc --backend c --version",
  env: "CC=gcc",
)

runs << Myc.new(
  name: "mycc(llvm, final)",
  cmd: "../mycc o --final --backend llvm",
  build_dir: "/tmp/myc_bench_la/mycc-llvm-final",
  output: "./bin_la_myc_llvm_final",
  version: "../mycc --backend llvm --version",
  env: "",
)

runs << Myc.new(
  name: "mycc(qbe, final)",
  cmd: "../mycc o --final --backend qbe",
  build_dir: "/tmp/myc_bench_la/mycc-qbe-final",
  output: "./bin_la_myc_qbe_final",
  version: "../mycc --backend qbe --version",
  env: "",
)

runs << Myc.new(
  name: "mycc(c, final, clang)",
  cmd: "../mycc o --final --backend c",
  build_dir: "/tmp/myc_bench_la/mycc-c-clang-final",
  output: "./bin_la_myc_c_clang_final",
  version: "../mycc --backend c --version",
  env: "CC=clang",
)

runs << Myc.new(
  name: "mycc(c, final, gcc)",
  cmd: "../mycc o --final --backend c",
  build_dir: "/tmp/myc_bench_la/mycc-c-gcc-final",
  output: "./bin_la_myc_c_gcc_final",
  version: "../mycc --backend c --version",
  env: "CC=gcc",
)

if ENV["FILTER"] && !ENV["FILTER"].empty?
  runs.select! { |r| r.name.downcase.include?(ENV["FILTER"].downcase) }
end

if ENV["MYC_CI"] == "1"
  runs.select! do |r|
    r.name == "mycc(qbe)" || r.name == "mycc(c, clang)" || r.name == "mycc(llvm)"
  end
end

runs.each do |run|
  run.build_all
end

runs.each do |run|
  puts "Run benchmark for #{run.name}"
  run.run
end

stats = runs.map do |run|
  [run.name, run.stats]
end

def markdown_table(stats)
  output = []
  output << "| Compiler | Build time | Build rss | Bench Runtime |"
  output << "|:-------|-------------:|-----:|----:|"

  stats.each do |compiler, data|
    build_obj = (data[:build_obj_time] * 1000).round
    mem = data[:avg_memory_mb]
    run = data[:run_time].round(1)

    output << "| #{compiler} | #{build_obj}ms | #{mem.to_i}Mb | #{run}s |"
  end

  output.join("\n")
end
puts 
puts
puts markdown_table(stats)

exit $exitst

