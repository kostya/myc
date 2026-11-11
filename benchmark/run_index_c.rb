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

def myc_run(backend, final)
  printf "Run mycc #{backend} #{final} ... "
  binary = "./bin_mycc_index_#{backend}_#{final}"
  cmd = "../mycc ../plugins/index-c/index.c c --backend #{backend} #{final ? "--final" : ""} #{binary}"
  `rm -f #{binary}`
  compile_time = measure { `#{cmd}` }
  run_time, ok = run_and_check(binary)
  res = [compile_time, run_time, ok ? "OK" : "ERR"]
  p res
  res
end

RES = []
%w{llvm c gm qbe}.each do |backend|
  {false => "", true => "--final"}.each do |final, flag|
    RES << ["mycc", backend, flag, *myc_run(backend, final)]
  end
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

%w{clang gcc}.each do |compiler|
  backend = compiler == "clang" ? "llvm" : "-"
  %w{-O0 -O1 -O2 -O3}.each do |flag|
    RES << [compiler, backend, flag, *c_run(compiler, flag)]
  end
end

RES << ["cproc", "qbe", "", *c_run("cproc", "")]

puts
puts "| Compiler | Backend | Flags | Compile (s) | Run (s) | Status |"
puts "|----------|---------|-------|-------------|---------|--------|"
RES.each do |compiler, backend, flags, compile_time, run_time, status|
  ct = compile_time ? compile_time.round(4) : ""
  rt = run_time ? run_time.round(4) : ""
  puts "| #{compiler} | #{backend} | #{flags} | #{ct} | #{rt} | #{status} |"
end