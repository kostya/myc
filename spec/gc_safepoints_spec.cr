require "./spec_helper"

class Myc::Backend::AbstractBackend
  def spec_dump_text : String
    input = data.values.first
    output = new_tmp_path("myc", "dump")
    mod, header = load_single(input)
    run_dump(mod, header, output)
    File.read(output)
  end

  def spec_write_obj(output : String)
    mod, header = load_single(data.values.first)
    run_obj(mod, header, output)
  end
end

private GC_IR = <<-MYC
FUNC :gc_root
  ARGS
    TYPE :ptr<void>
ENDFUNC

FUNC :collect
  ARGS
    TYPE :ptr<void>
ENDFUNC

FUNC :main
  BODY
    PUSH 8
    MALLOC :i8
    AS :ptr<void>
    CALL :collect
ENDFUNC
MYC

private def with_gc_ir(src : String, options = {} of String => String, &)
  path = Myc::Backend::AbstractBackend.new_tmp_path("gcsp", "myc")
  File.write(path, src)
  data = Myc::Cli::Data.new
  data.mode = :dump
  data.values << path
  options.each { |k, v| data.options[k] = v }
  backend = Myc::Backend::Llvm::Backend.new(data)
  begin
    yield backend, path
  ensure
    data.clean_temp_files
    File.delete(path) if File.exists?(path)
  end
end

private def llvm_stackmaps_writable?(obj : String) : Bool
  File.open(obj, "r") do |f|
    ident = Bytes.new(16)
    return false if f.read(ident) != 16
    return false unless ident[0] == 0x7f && ident[1] == 'E'.ord && ident[2] == 'L'.ord && ident[3] == 'F'.ord
    return false unless ident[4] == 2 && ident[5] == 1
    f.seek(40)
    shoff = f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
    f.seek(58)
    shentsize = f.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
    shnum = f.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
    shstrndx = f.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
    return false if shoff == 0 || shentsize != 64 || shnum == 0 || shstrndx >= shnum
    f.seek(shoff + shstrndx.to_u64 * 64)
    f.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
    f.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
    f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
    f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
    str_off = f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
    str_size = f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
    return false if str_size == 0 || str_size > 1_048_576
    f.seek(str_off)
    names = Bytes.new(str_size)
    return false if f.read(names) != str_size.to_i
    i = 0_u16
    while i < shnum
      f.seek(shoff + i.to_u64 * 64)
      name_off = f.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      f.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      flags = f.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
      if elf_section_name?(names, name_off, ".llvm_stackmaps")
        return flags.bits_set?(0x1_u64)
      end
      i = i &+ 1
    end
  end
  false
end

private def elf_section_name?(names : Bytes, off : UInt32, want : String) : Bool
  start = off.to_i
  return false if start < 0 || start >= names.size
  bytes = want.to_slice
  return false if start + bytes.size >= names.size
  i = 0
  while i < bytes.size
    return false if names[start + i] != bytes[i]
    i += 1
  end
  names[start + bytes.size] == 0
end

describe "GC safepoints (llvm)" do
  it "emits gc.statepoint when gc_root is declared" do
    with_gc_ir(GC_IR) do |backend, _|
      ll = backend.spec_dump_text
      ll.should contain("llvm.experimental.gc.statepoint")
      ll.should contain("statepoint-example")
    end
  end

  it "does not emit statepoints without a root hook" do
    src = <<-MYC
    FUNC :collect
      ARGS
        TYPE :ptr<void>
    ENDFUNC

    FUNC :main
      BODY
        PUSH 8
        MALLOC :i8
        AS :ptr<void>
        CALL :collect
    ENDFUNC
    MYC
    with_gc_ir(src) do |backend, _|
      ll = backend.spec_dump_text
      ll.should_not contain("llvm.experimental.gc.statepoint")
    end
  end

  it "honors --gc-root" do
    src = GC_IR.gsub("gc_root", "my_root")
    with_gc_ir(src, {"gc-root" => "my_root"}) do |backend, _|
      backend.spec_dump_text.should contain("llvm.experimental.gc.statepoint")
    end
  end

  it "honors --no-gc-safepoints" do
    with_gc_ir(GC_IR, {"no-gc-safepoints" => ""}) do |backend, _|
      backend.spec_dump_text.should_not contain("llvm.experimental.gc.statepoint")
    end
  end

  it "skips statepoints for ATTR :leaf callees" do
    src = <<-MYC
    FUNC :gc_root
      ARGS
        TYPE :ptr<void>
    ENDFUNC

    FUNC :collect
      ARGS
        TYPE :ptr<void>
      ATTRIBUTES
        ATTR :leaf
    ENDFUNC

    FUNC :main
      BODY
        PUSH 8
        MALLOC :i8
        AS :ptr<void>
        CALL :collect
    ENDFUNC
    MYC
    with_gc_ir(src) do |backend, _|
      backend.spec_dump_text.should_not contain("llvm.experimental.gc.statepoint")
    end
  end

  it "marks .llvm_stackmaps SHF_WRITE" do
    with_gc_ir(GC_IR) do |backend, _|
      obj = Myc::Backend::AbstractBackend.new_tmp_path("gcsp", "o")
      backend.spec_write_obj(obj)
      llvm_stackmaps_writable?(obj).should be_true
      File.delete(obj) if File.exists?(obj)
    end
  end
end
