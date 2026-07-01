abstract class Myc::Backend::AbstractBuilder
  getter backend : AbstractBackend
  getter layout : Layout
  getter std_funcs : Hash(String, Type::Fn)
  getter inspect_funcs : Hash(Type, String)
  getter inspect_type_fns : Hash(String, Type::Fn)

  def initialize(@backend, @layout)
    @std_funcs = add_std_funcs
    @inspect_funcs = Hash(Type, String).new
    @inspect_type_fns = Hash(String, Type::Fn).new
  end

  def add_std_funcs
    void = Mod::Typer::STD_TYPES["void"]
    i32 = Mod::Typer::STD_TYPES["i32"]
    i64 = Mod::Typer::STD_TYPES["i64"]
    u64 = Mod::Typer::STD_TYPES["u64"]
    f64 = Mod::Typer::STD_TYPES["f64"]
    u8p = Mod::Typer::STD_TYPES["ptr<u8>"]
    voidp = Mod::Typer::STD_TYPES["ptr<void>"]

    h = Hash(String, Type::Fn).new

    h["printf"] = Type::Fn.new([u8p], i32, vaarg: true)
    h["fprintf"] = Type::Fn.new([voidp, u8p], i32, vaarg: true)
    h["sprintf"] = Type::Fn.new([u8p, u8p], i32, vaarg: true)
    h["snprintf"] = Type::Fn.new([u8p, u64, u8p], i32, vaarg: true)
    h["malloc"] = Type::Fn.new([u64], voidp)
    h["calloc"] = Type::Fn.new([u64, u64], voidp)
    h["realloc"] = Type::Fn.new([voidp, u64], voidp)
    h["strncmp"] = Type::Fn.new([u8p, u8p, u64], i32)
    h["memcpy"] = Type::Fn.new([voidp, voidp, u64], voidp)
    h["memset"] = Type::Fn.new([voidp, i32, u64], voidp)
    h["memcmp"] = Type::Fn.new([voidp, voidp, u64], i32)
    h["free"] = Type::Fn.new([voidp], void)
    h["strlen"] = Type::Fn.new([u8p], u64)
    h["strcmp"] = Type::Fn.new([u8p, u8p], i32)
    h["strcpy"] = Type::Fn.new([u8p, u8p], u8p)
    h["rand"] = Type::Fn.new([] of Type, i32)
    h["exit"] = Type::Fn.new([i32], void)
    h["abort"] = Type::Fn.new([] of Type, void)
    h["fflush"] = Type::Fn.new([voidp], i32)
    h["putchar"] = Type::Fn.new([i32], i32)
    h["getchar"] = Type::Fn.new([] of Type, i32)
    h["puts"] = Type::Fn.new([u8p], i32)
    h["atoi"] = Type::Fn.new([u8p], i32)
    h["atof"] = Type::Fn.new([u8p], f64)
    h["abs"] = Type::Fn.new([i32], i32)
    h["strchr"] = Type::Fn.new([u8p, i32], u8p)

    h
  end

  abstract def init_value(ival : InitValue) : Value
  abstract def find_global(name : String) : Value?
  abstract def new_func(func_def : Mod::FuncDef) : AbstractFunc
  abstract def func_register(name : String, type_fn : Type::Fn)

  protected def escaped_string(s : String)
    s.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
  end

  abstract struct InitValue
    record Intval < InitValue, type : Type, val : Int64
    record Boolval < InitValue, type : Type, val : Bool
    record F32 < InitValue, type : Type, val : Float32
    record F64 < InitValue, type : Type, val : Float64
    record Str < InitValue, type : Type, str : String
    record GlobalRef < InitValue, type : Type, name : String
    record FnRef < InitValue, type : Type, name : String
    record StructInit < InitValue, type : Type, fields : Array(InitValue)
    record FlatInit < InitValue, type : Type, elements : Array(InitValue)
    record FlatStr < InitValue, type : Type, str : String
    record NullPtr < InitValue, type : Type
  end

  def init_val(values : Array(Source::Token::ArgType), type : Type, mod : Mod, loc : Location) : InitValue
    res = _init_val(values, type, mod, loc)
    unless values.empty?
      raise Error::ErrorLoc.new("extra unmatched values #{values.inspect}", loc)
    end
    res
  end

  private def _init_val(values : Array(Source::Token::ArgType), type : Type, mod : Mod, loc : Location) : InitValue
    raise Error::ErrorLoc.new("cant create primitive_value for #{type}, empty", loc) if values.size == 0

    case type
    when Type::IntType
      case value = values.shift
      when Int
        return InitValue::Intval.new(type, value)
      when String
        if value.size == 1
          return InitValue::Intval.new(type, value[0].ord)
        end
      end
    when Type::BoolType
      case value = values.shift
      when Bool
        return InitValue::Boolval.new(type, value)
      when Int
        return InitValue::Boolval.new(type, value != 0)
      end
    when Type::FloatType
      value = values.shift
      case type.bytes_count
      when 4
        case value
        when Int64, Float64
          return InitValue::F32.new(type, value.to_f32)
        end
      else
        case value
        when Int64, Float64
          return InitValue::F64.new(type, value.to_f64)
        end
      end
    when Type::EnumType, Type::EnumVariantType, Type::VoidType
      raise Error::ErrorLoc.new("cant create primitive_value for #{type}", loc)
    when Type::Fn
      case value = values.shift
      when String
        if f = mod.func_defs[value]?
          if f.type_fn.eq?(type)
            return InitValue::FnRef.new(type, value)
          else
            raise Error::ErrorLoc.new("fn #{value} have type #{f.type_fn}, but expected #{type}", loc)
          end
        else
          raise Error::ErrorLoc.new("fn #{value} not found!", loc)
        end
      when Int
        return InitValue::NullPtr.new(type) if value == 0
      end
    when Type::StructType
      res = Array(InitValue).new

      if values.size < type.data.size
        raise Error::ErrorLoc.new("struct expect at least #{type.data.size} value, but got #{values.size}", loc)
      end

      type.data.each do |subtype|
        res << _init_val(values, subtype, mod, loc)
      end

      return InitValue::StructInit.new(type, res)
    when Type::PtrType
      value = values.shift

      case value
      when String
        if g = mod.global_defs[value]?
          if g.type.eq?(type.target_type)
            return InitValue::GlobalRef.new(type, value)
          else
            raise Error::ErrorLoc.new("global #{value} have type #{g.type}, but expected #{type}", loc)
          end
        end
      when Int
        return InitValue::NullPtr.new(type) if value == 0
      end

      case tt = type.target_type
      when Type::IntType
        if tt.bytes_count == 1
          if value.is_a?(String)
            return InitValue::Str.new(type, value)
          end
        end
      end
    when Type::FlatType
      if type.target_type.eq?(mod.typer.u8)
        case value = values[0]
        when String
          if type.elements_count == value.size
            values.shift
            return InitValue::FlatStr.new(type, value)
          else
            raise Error::ErrorLoc.new("flat initialize with string bad size got: #{value.size}, expected: #{type.elements_count}", loc)
          end
        end
      end

      res = Array(InitValue).new

      if values.size < type.elements_count
        raise Error::ErrorLoc.new("flat expect at least #{type.elements_count} value, but got #{values.size}", loc)
      end

      type.elements_count.times do |index|
        val = _init_val(values, type.target_type, mod, loc)
        res << val
      end

      return InitValue::FlatInit.new(type, res)
    end

    raise Error::ErrorLoc.new("cant create primitive_value for #{type}", loc)
  end
end
