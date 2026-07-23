abstract class Myc::Type
  property hidden : Bool = false

  getter id_name : String
  getter backend_name : String

  getter loc : Location

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
    when StructType, FlatType, EnumType, EnumVariantType then true
    else                                                      false
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

  def structural_eq?(other : Type) : Bool
    return false unless self.class == other.class

    left = self
    case {left, other}
    when {StructType, StructType}
      return false unless left.data.size == other.data.size
      return false if left.explicit_alignment != other.explicit_alignment
      left.data.size.times do |i|
        return false unless left.data[i].structural_eq?(other.data[i])
      end
      true
    when {FlatType, FlatType}
      return false if left.explicit_alignment != other.explicit_alignment
      left.target_type.structural_eq?(other.target_type) && left.elements_count == other.elements_count
    when {EnumType, EnumType}
      return false unless left.data.size == other.data.size
      return false if left.index_type.nil? != other.index_type.nil?
      return false if (t = left.index_type) && !t.structural_eq?(other.index_type.not_nil!)
      return false if left.explicit_alignment != other.explicit_alignment
      return false if left.payload_type.nil? != other.payload_type.nil?
      return false if (t = left.payload_type) && !t.structural_eq?(other.payload_type.not_nil!)

      left.data.each do |name, variant_type|
        other_variant = other.data[name]?
        return false unless other_variant
        return false unless variant_type.structural_eq?(other_variant)
      end
      true
    when {EnumVariantType, EnumVariantType}
      return false unless left.position == other.position
      return false unless left.original_name == other.original_name
      return false if left.composite_value_type.nil? != other.composite_value_type.nil?
      return false if (t = left.composite_value_type) && !t.structural_eq?(other.composite_value_type.not_nil!)
      return false unless left.value_types.size == other.value_types.size

      left.value_types.size.times do |i|
        return false unless left.value_types[i].structural_eq?(other.value_types[i])
      end

      true
    when {PtrType, PtrType}
      left.target_type.id_name == other.target_type.id_name
    when {Fn, Fn}
      return false unless left.args.size == other.args.size && left.vaarg == other.vaarg
      left.args.size.times do |i|
        return false unless left.args[i].structural_eq?(other.args[i])
      end
      true
    when {IntType, IntType}
      left.bytes_count == other.bytes_count && left.signed == other.signed
    when {FloatType, FloatType}
      left.bytes_count == other.bytes_count
    when {BoolType, BoolType}, {VoidType, VoidType}
      true
    else
      false
    end
  end
end

require "./type/*"
