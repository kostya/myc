abstract class Myc::Backend::AbstractBuilder
  getter backend : AbstractBackend
  getter layout : Layout
  getter std_funcs : Hash(String, Type::Fn)
  getter inspect_funcs : Hash(Type, String)
  getter inspect_type_fns : Hash(String, Mod::FuncDef)

  def initialize(@backend, @layout)
    @std_funcs = add_std_funcs
    @inspect_funcs = Hash(Type, String).new
    @inspect_type_fns = Hash(String, Mod::FuncDef).new
  end

  def add_std_funcs
    void = Typer::STD_TYPES["void"]
    i32 = Typer::STD_TYPES["i32"]
    u32 = Typer::STD_TYPES["u32"]

    u64 = Typer::STD_TYPES["u64"]

    u8p = Typer::STD_TYPES["ptr<u8>"]
    voidp = Typer::STD_TYPES["ptr<void>"]

    f32 = Typer::STD_TYPES["f32"]
    f64 = Typer::STD_TYPES["f64"]

    h = Hash(String, Type::Fn).new
    loc = Location.new("std", 0)

    h["printf"] = Type::Fn.new(loc, [u8p], i32, vaarg: true)
    h["malloc"] = Type::Fn.new(loc, [u64], voidp)
    h["calloc"] = Type::Fn.new(loc, [u64, u64], voidp)
    h["memset"] = Type::Fn.new(loc, [voidp, i32, u64], voidp)
    h["free"] = Type::Fn.new(loc, [voidp], void)

    h
  end

  abstract def init_value(ival : InitValue) : Value
  abstract def find_global(name : String) : Value?
  abstract def new_func(func_def : Mod::FuncDef) : AbstractFunc
  abstract def func_register(name : String, func_def : Mod::FuncDef)

  def self.escaped_string(s : String)
    s.gsub("\\", "\\\\")
      .gsub("\"", "\\\"")
      .gsub("\n", "\\n")
      .gsub("\t", "\\t")
      .gsub("\r", "\\r")
  end

  abstract struct InitValue
    record Intval < InitValue, type : Type, val : Int64
    record Boolval < InitValue, type : Type, val : Bool
    record F32 < InitValue, type : Type, val : Float32
    record F64 < InitValue, type : Type, val : Float64
    record Str < InitValue, type : Type, str : String
    record Zero < InitValue, type : Type
    record FnRef < InitValue, type : Type, name : String
    record GlobalRef < InitValue, type : Type, name : String

    record StructInit < InitValue, type : Type, fields : Array(InitValue)
    record FlatInit < InitValue, type : Type, elements : Array(InitValue)
    record FlatStr < InitValue, type : Type, str : String
  end

  class ValuesParser
    getter values : Array(Source::Token::Value)
    getter type : Type
    getter mod : Mod
    getter loc : Location
    getter pos : Int32

    def initialize(@values, @type, @mod, @loc)
      @pos = 0
    end

    def parse : InitValue
      res = _parse(@type)
      raise error("extra unmatched values #{@values[pos..-1].map(&.val)}") if pos <= values.size - 1
      res
    end

    private def _parse(type : Type) : InitValue
      raise error("cant create primitive_value for #{type}, empty") if pos >= values.size

      case type
      when Type::IntType
        value = @values[@pos]
        @pos += 1
        case value
        when Source::Token::IntValue
          return InitValue::Intval.new(type, value.val)
        when Source::Token::StringValue
          return InitValue::Intval.new(type, value.val[0].ord) if value.val.size == 1
        end
      when Type::BoolType
        value = @values[@pos]
        @pos += 1
        case value
        when Source::Token::BoolValue
          return InitValue::Boolval.new(type, value.val)
        when Source::Token::IntValue
          return InitValue::Boolval.new(type, value.val != 0)
        end
      when Type::FloatType
        value = @values[@pos]
        @pos += 1

        case type.bytes_count
        when 4
          case value
          when Source::Token::FloatValue, Source::Token::IntValue
            return InitValue::F32.new(type, value.val.to_f32)
          end
        else
          case value
          when Source::Token::FloatValue, Source::Token::IntValue
            return InitValue::F64.new(type, value.val.to_f64)
          end
        end
      when Type::EnumType, Type::EnumVariantType, Type::VoidType
        raise error("cant create primitive_value for #{type}")
      when Type::Fn
        value = @values[@pos]
        @pos += 1

        case value
        when Source::Token::StringValue
          if f = mod.func_defs[value.val]?
            if f.type_fn.eq?(type)
              return InitValue::FnRef.new(type, value.val)
            else
              raise error("fn #{value.val} have type #{f.type_fn}, but expected #{type}")
            end
          else
            raise error("fn #{value.val} not found!")
          end
        when Source::Token::IntValue
          return InitValue::Zero.new(type) if value.val == 0
        end
      when Type::PtrType
        value = @values[@pos]
        @pos += 1

        case value
        when Source::Token::StringValue
          if g = mod.global_defs[value.val]?
            if g.type.eq?(type.target_type)
              return InitValue::GlobalRef.new(type, value.val)
            else
              raise error("global #{value.val} have type #{g.type}, but expected #{type}")
            end
          end
        when Source::Token::IntValue
          return InitValue::Zero.new(type) if value.val == 0
        end

        case tt = type.target_type
        when Type::IntType
          if tt.bytes_count == 1
            case value
            when Source::Token::StringValue
              return InitValue::Str.new(type, value.val)
            end
          end
        end
      when Type::StructType
        res = Array(InitValue).new

        remain_count = values.size - pos

        if remain_count < type.data.size
          raise error("struct expect at least #{type.data.size} value, but got #{remain_count}")
        end

        type.data.each do |subtype|
          res << _parse(subtype)
        end

        return InitValue::StructInit.new(type, res)
      when Type::FlatType
        if type.target_type.eq?(mod.typer.u8)
          case value = values[pos]
          when Source::Token::StringValue
            if type.elements_count == value.val.bytesize
              @pos += 1
              return InitValue::FlatStr.new(type, value.val)
            else
              raise error("flat initialize with string bad size got: #{value.val.bytesize}, expected: #{type.elements_count}")
            end
          end
        end

        res = Array(InitValue).new

        remain_count = values.size - pos
        if remain_count < type.elements_count
          raise error("flat expect at least #{type.elements_count} value, but got #{remain_count}")
        end

        type.elements_count.times do |index|
          res << _parse(type.target_type)
        end

        return InitValue::FlatInit.new(type, res)
      end

      raise error("cant create primitive_value for #{type}")
    end

    def error(msg)
      Error::ErrorLoc.new(msg, loc)
    end
  end
end
