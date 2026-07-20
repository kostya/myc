class Myc::Typer
  STD_TYPES = begin
    h = Hash(String, Type).new

    std_loc = Location.new("std", 0)

    h["void"] = Type::VoidType.new(std_loc, "void")
    h["bool"] = Type::BoolType.new(std_loc, "bool")

    h["i8"] = Type::IntType.new(std_loc, "i8", 1, true)
    h["u8"] = Type::IntType.new(std_loc, "u8", 1, false)
    h["i16"] = Type::IntType.new(std_loc, "i16", 2, true)
    h["u16"] = Type::IntType.new(std_loc, "u16", 2, false)
    h["i32"] = Type::IntType.new(std_loc, "i32", 4, true)
    h["u32"] = Type::IntType.new(std_loc, "u32", 4, false)
    h["i64"] = Type::IntType.new(std_loc, "i64", 8, true)
    h["u64"] = Type::IntType.new(std_loc, "u64", 8, false)

    h["f32"] = Type::FloatType.new(std_loc, "f32", 4)
    h["f64"] = Type::FloatType.new(std_loc, "f64", 8)

    h.each do |name, type|
      h["ptr<#{name}>"] = Type::PtrType.new(std_loc, "ptr<#{name}>", type)
    end

    h.rehash
    h
  end

  getter types_cache : Hash(String, Type)

  def initialize
    @types_cache = Hash(String, Type).new
    @unique_id = 0_u64
  end

  {% for tp in %w{i32 u32 i64 u64 i16 u16 i8 u8 f64 f32 bool void} %}
    def {{tp.id}} : Type
      STD_TYPES[{{tp}}]
    end

    def {{tp.id}}p : Type
      STD_TYPES["ptr<{{tp.id}}>"]
	  end
  {% end %}

  def find_in_caches(name : String) : Type?
    if tp = @types_cache[name]?
      return tp
    end

    if tp = STD_TYPES[name]?
      @types_cache[name] = tp
      return tp
    end
  end

  def find(id_name : String, loc : Location) : Type
    find_in_caches(id_name) || Parser.new(id_name, self, loc).get_type
  end

  def to_ptr(type : Type, loc : Location) : Type
    find("ptr<#{type.id_name}>", loc)
  end
end

require "./typer/*"
