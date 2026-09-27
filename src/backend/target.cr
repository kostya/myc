struct Myc::Backend::Target
  enum Arch
    Arm64
    X86_64
    X86
    Wasm32
    Unknown
  end

  enum OS
    Darwin
    Linux
    Windows
    Wasm
    Unknown
  end

  getter arch : Arch
  getter os : OS
  getter original_triple : String?

  def initialize(@arch, @os = OS::Unknown, @original_triple = nil)
  end

  def self.from_triple(triple : String) : self
    arch = case triple
           when /aarch64|arm64/       then Arch::Arm64
           when /x86_64|amd64/        then Arch::X86_64
           when /i386|i486|i586|i686/ then Arch::X86
           when /wasm32/              then Arch::Wasm32
           else                            Arch::Unknown
           end

    os = case triple
         when /darwin|macos|ios|tvos|watchos/ then OS::Darwin
         when /linux/                         then OS::Linux
         when /windows|mingw|msvc/            then OS::Windows
         when /wasm|emscripten/               then OS::Wasm
         else                                      OS::Unknown
         end

    self.new(arch, os, triple)
  end

  def pointer_size
    case arch
    in .arm64?, .x86_64?, .unknown? then 8_u64
    in .x86?, .wasm32?              then 4_u64
    end
  end

  def pointer_alignment
    case arch
    in .arm64?, .x86_64?, .unknown? then 8_u64
    in .x86?, .wasm32?              then 4_u64
    end
  end

  def va_arg_word_fill? : Bool
    os.darwin? && arch.arm64?
  end

  def va_arg_requires_extension_for?(bytes : UInt64) : Bool
    va_arg_word_fill? && bytes < 8
  end

  def triple : String
    original_triple || default_triple
  end

  private def default_triple
    case {arch, os}
    in {Arch::Arm64, OS::Darwin}  then "arm64-apple-darwin"
    in {Arch::Arm64, OS::Linux}   then "aarch64-unknown-linux-gnu"
    in {Arch::X86_64, OS::Darwin} then "x86_64-apple-darwin"
    in {Arch::X86_64, OS::Linux}  then "x86_64-unknown-linux-gnu"
    in {Arch::X86, OS::Linux}     then "i386-unknown-linux-gnu"
    in {Arch::Wasm32, OS::Wasm}   then "wasm32-unknown-unknown"
    in {Arch::Unknown, _}         then "unknown-unknown-unknown"
    in {_, _}                     then "#{arch}-unknown-#{os}"
    end
  end
end
