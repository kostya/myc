# Run run_lang_arena.rb before this script to compile deps and other compilers results.

def measure
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t).to_f
end

ROOT = "../plugins/LangArena"

def compile(backend, output, flag)
  measure do
    link_flags = "MYC_LINKER_FLAGS='-lpcre2-8 #{ROOT}/c/target/deps/prod/libbase64.o #{ROOT}/c/target/deps/prod/yyjson.o' "
    cmd = "#{link_flags} ../myc-#{backend} #{ROOT}/myc/*.myc c #{output} #{flag}"
    `#{cmd}`
  end
end

def run(binary)
  c = "#{binary} #{ROOT}/run.js"
  res = `#{c}`
  line = res.split("\n").find { |l| l.include?("Summary") }
  if line && line.include?("50, 50, ") && line =~ /Summary:\s*(\d+\.\d+)s/
    delta = $1.to_f
    puts "OK in #{delta}"
    delta
  else
    raise "ERROR #{line}"
  end
end

t1 = Hash.new(0)
t2 = Hash.new(0)

OPTS = [
  {
    "name" => "myc-llvm(default)",
    "opts" => ["llvm", "./bin_langarena_myc_llvm_default", ""],
  },
  {
    "name" => "myc-llvm(final)",
    "opts" => ["llvm", "./bin_langarena_myc_llvm_final", "--final"],
  },
  {
    "name" => "myc-qbe(default)",
    "opts" => ["qbe", "./bin_langarena_myc_qbe_default", ""],
  },
  {
    "name" => "myc-c(default, clang)",
    "opts" => ["c", "./bin_langarena_myc_c_clang_default", ""],
  },
  {
    "name" => "myc-c(final, clang)",
    "opts" => ["c", "./bin_langarena_myc_c_clang_final", "--final"],
  },
]

OPTS.each do |h|
  puts "Compile #{h["name"]}"
  t1[h["name"]] = compile(*h["opts"])
end

OPTS.each do |h|
  puts "Run #{h["name"]}"
  t2[h["name"]] = run(h["opts"][1])
end

p t1
p t2

def markdown_table(build_times, run_times)
  output = []
  output << "| Compiler | Build time | Runtime |"
  output << "|:-------|-------------:|-----:|"

  build_times.each do |compiler, time|
    ms = (time * 1000).round
    run = "#{run_times[compiler].round(1)}s"
    output << "| #{compiler} | #{ms}ms | #{run} |"
  end

  output.join("\n")
end

puts
puts markdown_table(t1, t2)