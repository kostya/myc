abstract class Myc::Type
  property hidden : Bool = false

  property id_name : String
  property backend_name : String

  property loc : Location

  def initialize(@loc, @id_name)
    @backend_name = normalize_name(id_name)
  end

  def to_s(io)
    repr(io)
  end

  def repr(io)
    io << self.id_name
  end

  def field_type?(index : Int32) : Tuple(Int32, Type)?
  end

  def needs_blit? : Bool
    case self
    when StructType, FlatType, EnumType, EnumVariantType, VaListType then true
    else                                                                  false
    end
  end

  def eq?(other : Type)
    self == other
  end

  protected def normalize_name(name : String) : String
    name.gsub(/[^a-zA-Z0-9_]/, "_")
  end

  def flat_elements_count : UInt64
    1_u64
  end

  def finished!
    self
  end

  def to_unsafe_ptr
    Type::PtrType.new(@loc, "ptr<#{self.id_name}>", self)
  end

  # Heap pointers and aggregates that contain them. Used by myc-llvm
  # safepoints: spill these across CALL so a moving GC can rewrite the
  # slots. C pointers that are not heap objects are still PtrType; the
  # collector leaves non-heap words unchanged.
  def gc_pointer? : Bool
    case self
    when Type::PtrType
      true
    when Type::StructType
      self.as(Type::StructType).data.any?(&.gc_pointer?)
    else
      false
    end
  end
end

require "./type/*"
