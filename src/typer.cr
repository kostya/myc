class Myc::Typer
  getter map : Hash(String, Type)

  STD_TYPES = %w{i32 u32 i64 u64 i16 u16 i8 u8 f64 f32 bool void}

  {% for tp in STD_TYPES %}
    getter {{tp.id}} : Type
    getter {{tp.id}}p : Type
  {% end %}

  def initialize
    @map = Hash(String, Type).new

    std_loc = Location.new("std", 0)

    @void = Type::VoidType.new(std_loc, "void").finished!
    @bool = Type::BoolType.new(std_loc, "bool").finished!

    @i8 = Type::IntType.new(std_loc, "i8", 1, true).finished!
    @u8 = Type::IntType.new(std_loc, "u8", 1, false).finished!
    @i16 = Type::IntType.new(std_loc, "i16", 2, true).finished!
    @u16 = Type::IntType.new(std_loc, "u16", 2, false).finished!
    @i32 = Type::IntType.new(std_loc, "i32", 4, true).finished!
    @u32 = Type::IntType.new(std_loc, "u32", 4, false).finished!
    @i64 = Type::IntType.new(std_loc, "i64", 8, true).finished!
    @u64 = Type::IntType.new(std_loc, "u64", 8, false).finished!

    @f32 = Type::FloatType.new(std_loc, "f32", 4).finished!
    @f64 = Type::FloatType.new(std_loc, "f64", 8).finished!

    @voidp = Type::PtrType.new(std_loc, "ptr<void>", @void).finished!
    @boolp = Type::PtrType.new(std_loc, "ptr<bool>", @bool).finished!
    @i8p = Type::PtrType.new(std_loc, "ptr<i8>", @i8).finished!
    @u8p = Type::PtrType.new(std_loc, "ptr<u8>", @u8).finished!
    @i16p = Type::PtrType.new(std_loc, "ptr<i16>", @i16).finished!
    @u16p = Type::PtrType.new(std_loc, "ptr<u16>", @u16).finished!
    @i32p = Type::PtrType.new(std_loc, "ptr<i32>", @i32).finished!
    @u32p = Type::PtrType.new(std_loc, "ptr<u32>", @u32).finished!

    @i64p = Type::PtrType.new(std_loc, "ptr<i64>", @i64).finished!
    @u64p = Type::PtrType.new(std_loc, "ptr<u64>", @u64).finished!

    @f32p = Type::PtrType.new(std_loc, "ptr<f32>", @f32).finished!
    @f64p = Type::PtrType.new(std_loc, "ptr<f64>", @f64).finished!

    {% for tp in STD_TYPES %}
      map[{{tp}}] = {{tp.id}}
      map["ptr<" + {{tp}} + ">"] = @{{tp.id}}p
    {% end %}

    map.rehash
  end

  def find_in_caches(name : String) : Type?
    @map[name]?
  end

  def find(id_name : String, loc : Location) : Type
    find_in_caches(id_name) || Parser.new(id_name, self, loc).get_type
  end

  def to_ptr(type : Type, loc : Location) : Type
    find("ptr<#{type.id_name}>", loc)
  end

  def to_unsigned(type : Type::IntType) : Type
    find("u" + type.id_name[1..-1], Location.new("", 0))
  end
end

require "./typer/*"
