{% unless flag?(:win32) %}
  require "c/dlfcn"
{% end %}

module Myc::Backend::GM
  module NativeAPI
    alias AbiVersionFn = Proc(UInt32)
    alias VersionFn = Proc(UInt8*)
    alias CreateFn = Proc(UInt32, UInt32, LibGM::Module*)
    alias DestroyFn = Proc(LibGM::Module*, Nil)
    alias ErrorFn = Proc(LibGM::Module*, UInt8*)
    alias SymbolFn = Proc(LibGM::Module*, UInt8*, UInt32, UInt32)
    alias SignatureFn = Proc(LibGM::Module*, UInt64, UInt64*, UInt32, UInt32, UInt32)
    alias RecordFn = Proc(LibGM::Module*, UInt64, UInt32, LibGM::Field*, UInt32, UInt64)
    alias SymbolFactFn = Proc(LibGM::Module*, UInt32, UInt32, UInt32, Int32)
    alias FunctionFn = Proc(LibGM::Module*, UInt32, UInt32, UInt32, UInt32, Int32)
    alias GlobalFn = Proc(LibGM::Module*, UInt32, UInt64, UInt32, UInt32, LibGM::DataItem*, UInt32, UInt32, Int32)
    alias ReserveFn = Proc(LibGM::Module*, UInt32, LibGM::BodyCounts*, LibGM::BodyBuffers*, Int32)
    alias CommitFn = Proc(LibGM::Module*, UInt32, LibGM::BodyCounts*, UInt32, Int32)
    alias ValidateFn = Proc(LibGM::Module*, Int32)
    alias WriteFn = Proc(LibGM::Module*, UInt8*, Int32)
    alias CompileFn = Proc(LibGM::Module*, UInt32, UInt32, Int32)
    alias ObjectDataFn = Proc(LibGM::Module*, UInt8*)
    alias ObjectSizeFn = Proc(LibGM::Module*, UInt64)

    {% unless flag?(:gm_static) %}
      @@library : Library?
      @@ready = Atomic(Bool).new(false)
      @@library_lock = Mutex.new

      private def self.library : Library
        return @@library.not_nil! if @@ready.get(:acquire)
        @@library_lock.synchronize do
          unless @@ready.get(:relaxed)
            @@library = Library.new
            @@ready.set(true, :release)
          end
          @@library.not_nil!
        end
      end
    {% end %}

    def self.abi_version : UInt32
      {% if flag?(:gm_static) %}
        LibGM.abi_version
      {% else %}
        library.abi_version.call
      {% end %}
    end

    def self.version : String
      {% if flag?(:gm_static) %}
        String.new(LibGM.version)
      {% else %}
        String.new(library.version.call)
      {% end %}
    end

    def self.create(version : UInt32, target : IRTarget)
      {% if flag?(:gm_static) %}
        LibGM.create(version, target.value)
      {% else %}
        library.create.call(version, target.value)
      {% end %}
    end

    def self.destroy(mod : LibGM::Module*)
      {% if flag?(:gm_static) %}
        LibGM.destroy(mod)
      {% else %}
        library.destroy.call(mod)
      {% end %}
    end

    def self.error(mod : LibGM::Module*)
      {% if flag?(:gm_static) %}
        LibGM.error(mod)
      {% else %}
        library.error.call(mod)
      {% end %}
    end

    def self.symbol(mod : LibGM::Module*, name : String, length : Int)
      {% if flag?(:gm_static) %}
        LibGM.symbol(mod, name.to_unsafe, length.to_u32)
      {% else %}
        library.symbol.call(mod, name.to_unsafe, length.to_u32)
      {% end %}
    end

    def self.signature(mod : LibGM::Module*, result : UInt64, params : UInt64*, count : Int, arity : IRArity)
      {% if flag?(:gm_static) %}
        LibGM.signature(mod, result, params, count.to_u32, arity.value)
      {% else %}
        library.signature.call(mod, result, params, count.to_u32, arity.value)
      {% end %}
    end

    def self.record(mod : LibGM::Module*, bytes : UInt64, alignment : UInt64, fields : LibGM::Field*, count : Int)
      {% if flag?(:gm_static) %}
        LibGM.record(mod, bytes, alignment.to_u32, fields, count.to_u32)
      {% else %}
        library.record.call(mod, bytes, alignment.to_u32, fields, count.to_u32)
      {% end %}
    end

    def self.symbol_fact(mod : LibGM::Module*, symbol : Int, key : IRKey, value : Bool)
      {% if flag?(:gm_static) %}
        LibGM.symbol_fact(mod, symbol.to_u32, key.value, value ? 1_u32 : 0_u32)
      {% else %}
        library.symbol_fact.call(mod, symbol.to_u32, key.value, value ? 1_u32 : 0_u32)
      {% end %}
    end

    def self.function(mod : LibGM::Module*, symbol : Int, signature : Int, binding : IRBinding, form : IRFunctionForm)
      {% if flag?(:gm_static) %}
        LibGM.function(mod, symbol.to_u32, signature.to_u32, binding.value, form.value)
      {% else %}
        library.function.call(mod, symbol.to_u32, signature.to_u32, binding.value, form.value)
      {% end %}
    end

    def self.global(mod : LibGM::Module*, symbol : Int, type : UInt64, binding : IRBinding, storage : IRStorage, items : LibGM::DataItem*, count : Int, form : IRGlobalForm)
      {% if flag?(:gm_static) %}
        LibGM.global(mod, symbol.to_u32, type, binding.value, storage.value, items, count.to_u32, form.value)
      {% else %}
        library.global.call(mod, symbol.to_u32, type, binding.value, storage.value, items, count.to_u32, form.value)
      {% end %}
    end

    def self.reserve(mod : LibGM::Module*, symbol : Int, minimum : LibGM::BodyCounts*, buffers : LibGM::BodyBuffers*)
      {% if flag?(:gm_static) %}
        LibGM.reserve(mod, symbol.to_u32, minimum, buffers)
      {% else %}
        library.reserve.call(mod, symbol.to_u32, minimum, buffers)
      {% end %}
    end

    def self.commit(mod : LibGM::Module*, symbol : Int, counts : LibGM::BodyCounts*, temp_count : Int)
      {% if flag?(:gm_static) %}
        LibGM.commit(mod, symbol.to_u32, counts, temp_count.to_u32)
      {% else %}
        library.commit.call(mod, symbol.to_u32, counts, temp_count.to_u32)
      {% end %}
    end

    def self.validate(mod : LibGM::Module*)
      {% if flag?(:gm_static) %}
        LibGM.validate(mod)
      {% else %}
        library.validate.call(mod)
      {% end %}
    end

    def self.write(mod : LibGM::Module*, path : String)
      {% if flag?(:gm_static) %}
        LibGM.write(mod, path.to_unsafe)
      {% else %}
        library.write.call(mod, path.to_unsafe)
      {% end %}
    end

    def self.compile(mod : LibGM::Module*, level : Int, code : IRCodeForm)
      {% if flag?(:gm_static) %}
        LibGM.compile(mod, level.to_u32, code.value)
      {% else %}
        library.compile.call(mod, level.to_u32, code.value)
      {% end %}
    end

    def self.object_data(mod : LibGM::Module*)
      {% if flag?(:gm_static) %}
        LibGM.object_data(mod)
      {% else %}
        library.object_data.call(mod)
      {% end %}
    end

    def self.object_size(mod : LibGM::Module*)
      {% if flag?(:gm_static) %}
        LibGM.object_size(mod)
      {% else %}
        library.object_size.call(mod)
      {% end %}
    end

    private class Library
      @handle : Void*
      getter abi_version : AbiVersionFn
      getter version : VersionFn
      getter create : CreateFn
      getter destroy : DestroyFn
      getter error : ErrorFn
      getter symbol : SymbolFn
      getter signature : SignatureFn
      getter record : RecordFn
      getter symbol_fact : SymbolFactFn
      getter function : FunctionFn
      getter global : GlobalFn
      getter reserve : ReserveFn
      getter commit : CommitFn
      getter validate : ValidateFn
      getter write : WriteFn
      getter compile : CompileFn
      getter object_data : ObjectDataFn
      getter object_size : ObjectSizeFn

      def initialize
        @handle = Library.open_library
        @abi_version = AbiVersionFn.new(Library.resolve(@handle, "cppgm_lowir_abi_version"), Pointer(Void).null)
        @version = VersionFn.new(Library.resolve(@handle, "cppgm_lowir_version"), Pointer(Void).null)
        @create = CreateFn.new(Library.resolve(@handle, "cppgm_lowir_create"), Pointer(Void).null)
        @destroy = DestroyFn.new(Library.resolve(@handle, "cppgm_lowir_destroy"), Pointer(Void).null)
        @error = ErrorFn.new(Library.resolve(@handle, "cppgm_lowir_error"), Pointer(Void).null)
        @symbol = SymbolFn.new(Library.resolve(@handle, "cppgm_lowir_symbol"), Pointer(Void).null)
        @signature = SignatureFn.new(Library.resolve(@handle, "cppgm_lowir_signature"), Pointer(Void).null)
        @record = RecordFn.new(Library.resolve(@handle, "cppgm_lowir_record"), Pointer(Void).null)
        @symbol_fact = SymbolFactFn.new(Library.resolve(@handle, "cppgm_lowir_symbol_fact"), Pointer(Void).null)
        @function = FunctionFn.new(Library.resolve(@handle, "cppgm_lowir_function"), Pointer(Void).null)
        @global = GlobalFn.new(Library.resolve(@handle, "cppgm_lowir_global"), Pointer(Void).null)
        @reserve = ReserveFn.new(Library.resolve(@handle, "cppgm_lowir_body_reserve"), Pointer(Void).null)
        @commit = CommitFn.new(Library.resolve(@handle, "cppgm_lowir_body_commit"), Pointer(Void).null)
        @validate = ValidateFn.new(Library.resolve(@handle, "cppgm_lowir_validate"), Pointer(Void).null)
        @write = WriteFn.new(Library.resolve(@handle, "cppgm_lowir_write"), Pointer(Void).null)
        @compile = CompileFn.new(Library.resolve(@handle, "cppgm_lowir_compile"), Pointer(Void).null)
        @object_data = ObjectDataFn.new(Library.resolve(@handle, "cppgm_lowir_object_data"), Pointer(Void).null)
        @object_size = ObjectSizeFn.new(Library.resolve(@handle, "cppgm_lowir_object_size"), Pointer(Void).null)
      end

      def self.open_library : Void*
        {% if flag?(:win32) %}
          raise "The GM library backend requires Linux or macOS"
        {% else %}
          name = {% if flag?(:darwin) %} "libcppgm_lowir.dylib" {% else %} "libcppgm_lowir.so" {% end %}
          paths = if configured = ENV["GM_LIBRARY"]?
                    [configured]
                  else
                    candidates = [name]
                    if executable = Process.executable_path
                      candidates << File.join(File.dirname(executable), name)
                    end
                    candidates << File.expand_path("../../../plugins/cppgm/lib/#{name}", __DIR__)
                    candidates
                  end
          paths.each do |path|
            handle = LibC.dlopen(path, LibC::RTLD_NOW | LibC::RTLD_LOCAL)
            return handle unless handle.null?
          end
          detail = LibC.dlerror
          message = detail.null? ? "unknown loader error" : String.new(detail)
          raise "Cannot load GM backend library (#{paths.join(", ")}): #{message}. Set GM_LIBRARY to its path."
        {% end %}
      end

      def self.resolve(handle : Void*, name : String) : Void*
        {% if flag?(:win32) %}
          raise "The GM library backend requires Linux or macOS"
        {% else %}
          symbol = LibC.dlsym(handle, name)
          raise "GM backend library is missing #{name}; install cppgm 0.9.2 or later (LowIR ABI v#{ABI_VERSION})" if symbol.null?
          symbol
        {% end %}
      end
    end
  end
end
