require "fileutils"

unless File.directory?("../plugins/index-c")
  `git clone https://github.com/kostya/index-c.git ../plugins/index-c`
end

def measure
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t).to_f
end

def parse_summary(st)
  m = st.match(/Summary:\s*([\d.]+)s/)
  m ? m[1].to_f : nil
end

def run_and_check(binary)
  st = `#{binary} 2>&1`
  ok = st.include?("50, 50, 0")
  rt = parse_summary(st)
  print(ok ? " OK " : " ERR ")
  [rt, ok]
end

def myc_run(backend, flag)
  printf "Run mycc #{backend} #{flag} ... "
  binary = "./bin_mycc_index_#{backend}_#{flag.gsub(/[^a-zA-Z0-9]/, '_')}"
  cmd = "../mycc ../plugins/index-c/index.c c --backend #{backend} #{flag} #{binary}"
  `rm -f #{binary}`
  compile_time = measure { `#{cmd}` }
  run_time, ok = run_and_check(binary)
  res = [compile_time, run_time, ok ? "OK" : "ERR"]
  p res
  res
end

def c_run(compiler, flags)
  printf "Run #{compiler} #{flags} ... "
  binary = "./bin_c_index_#{compiler}_#{flags.gsub(/[^a-zA-Z0-9]/, '_')}"
  cmd = "#{compiler} ../plugins/index-c/index.c #{flags} -lm -lpthread -o #{binary}"
  `rm -f #{binary}`
  compile_time = measure { `#{cmd}` }
  run_time, ok = run_and_check(binary)
  res = [compile_time, run_time, ok ? "OK" : "ERR"]
  p res
  res
end

ALL_FLAGS = []
%w{llvm c gm qbe}.each do |backend|
  ["", "--final"].each do |flag|
    ALL_FLAGS << ["mycc", backend, flag]
  end
end

%w{clang gcc}.each do |compiler|
  backend = compiler == "clang" ? "llvm" : "-"
  %w{-O0 -O1 -O2 -O3}.each do |flag|
    ALL_FLAGS << [compiler, backend, flag]
  end
end

ALL_FLAGS << ["cproc", "qbe", ""]

if ENV["MYC_CI"] == "1"
  ALL_FLAGS = [
    ["mycc", "llvm", "--final"],
    ["mycc", "gm", "--final"],
    ["mycc", "gm", ""],
    ["mycc", "qbe", ""],
    ["clang", "llvm", "-O3"],
  ]
end

RES = []

ALL_FLAGS.each do |(compiler, backend, flag)|
  if compiler == "mycc"
    RES << [compiler, backend, flag, *myc_run(backend, flag)]
  else
    RES << [compiler, backend, flag, *c_run(compiler, flag)]
  end
end

puts
puts "| Compiler | Backend | Flags | Compile (s) | Run (s) | Status |"
puts "|----------|---------|-------|-------------|---------|--------|"
RES.each do |compiler, backend, flags, compile_time, run_time, status|
  ct = compile_time ? compile_time.round(4) : ""
  rt = run_time ? run_time.round(4) : ""
  puts "| #{compiler} | #{backend} | #{flags} | #{ct} | #{rt} | #{status} |"
end
