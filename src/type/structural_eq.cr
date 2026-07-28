class Myc::Type
  def structural_eq_with_reason?(other : Type) : {Bool, String}
    return {false, "Class mismatch: #{self.class} vs #{other.class}"} unless self.class == other.class

    left = self
    case {left, other}
    when {StructType, StructType}
      return {false, "Struct data size mismatch: #{left.data.size} vs #{other.data.size}"} unless left.data.size == other.data.size

      if left.explicit_alignment != other.explicit_alignment
        return {false, "Struct explicit alignment mismatch: #{left.explicit_alignment} vs #{other.explicit_alignment}"}
      end

      left.data.size.times do |i|
        result, reason = left.data[i].structural_eq_with_reason?(other.data[i])
        return {false, "Struct field [#{i}] mismatch: #{reason}"} unless result
      end

      {true, "Structs are structurally equal"}
    when {FlatType, FlatType}
      if left.explicit_alignment != other.explicit_alignment
        return {false, "FlatType explicit alignment mismatch: #{left.explicit_alignment} vs #{other.explicit_alignment}"}
      end

      result, reason = left.target_type.structural_eq_with_reason?(other.target_type)
      return {false, "FlatType target type mismatch: #{reason}"} unless result

      if left.elements_count != other.elements_count
        return {false, "FlatType elements count mismatch: #{left.elements_count} vs #{other.elements_count}"}
      end

      {true, "FlatTypes are structurally equal"}
    when {EnumType, EnumType}
      return {false, "Enum data size mismatch: #{left.data.size} vs #{other.data.size}"} unless left.data.size == other.data.size

      if left.index_type.nil? != other.index_type.nil?
        return {false, "Enum index type presence mismatch: #{left.index_type.nil? ? "absent" : "present"} vs #{other.index_type.nil? ? "absent" : "present"}"}
      end

      if (t = left.index_type) && !t.structural_eq_with_reason?(other.index_type.not_nil!)[0]
        idx_result, idx_reason = t.structural_eq_with_reason?(other.index_type.not_nil!)
        return {false, "Enum index type mismatch: #{idx_reason}"}
      end

      if left.explicit_alignment != other.explicit_alignment
        return {false, "Enum explicit alignment mismatch: #{left.explicit_alignment} vs #{other.explicit_alignment}"}
      end

      if left.payload_type.nil? != other.payload_type.nil?
        return {false, "Enum payload type presence mismatch: #{left.payload_type.nil? ? "absent" : "present"} vs #{other.payload_type.nil? ? "absent" : "present"}"}
      end

      if (t = left.payload_type) && !t.structural_eq_with_reason?(other.payload_type.not_nil!)[0]
        payload_result, payload_reason = t.structural_eq_with_reason?(other.payload_type.not_nil!)
        return {false, "Enum payload type mismatch: #{payload_reason}"}
      end

      left.data.each do |name, variant_type|
        original_name = variant_type.original_name
        found = other.data.find { |_, vt| vt.original_name == original_name }

        unless found
          return {false, "Enum variant '#{name}' missing in other enum"}
        end

        other_variant = found[1]

        result, reason = variant_type.structural_eq_with_reason?(other_variant)
        return {false, "Enum variant '#{name}' mismatch: #{reason}"} unless result
      end

      {true, "Enums are structurally equal"}
    when {EnumVariantType, EnumVariantType}
      if left.position != other.position
        return {false, "Enum variant position mismatch: #{left.position} vs #{other.position}"}
      end

      if left.original_name != other.original_name
        return {false, "Enum variant original name mismatch: '#{left.original_name}' vs '#{other.original_name}'"}
      end

      if left.composite_value_type.nil? != other.composite_value_type.nil?
        return {false, "Enum variant composite value type presence mismatch"}
      end

      if (t = left.composite_value_type) && !t.structural_eq_with_reason?(other.composite_value_type.not_nil!)[0]
        composite_result, composite_reason = t.structural_eq_with_reason?(other.composite_value_type.not_nil!)
        return {false, "Enum variant composite value type mismatch: #{composite_reason}"}
      end

      if left.value_types.size != other.value_types.size
        return {false, "Enum variant value types size mismatch: #{left.value_types.size} vs #{other.value_types.size}"}
      end

      left.value_types.size.times do |i|
        result, reason = left.value_types[i].structural_eq_with_reason?(other.value_types[i])
        return {false, "Enum variant value type [#{i}] mismatch: #{reason}"} unless result
      end

      {true, "Enum variants are structurally equal"}
    when {PtrType, PtrType}
      if left.target_type.id_name == other.target_type.id_name
        {true, "Pointer types are structurally equal"}
      else
        {false, "Pointer target type mismatch: '#{left.target_type.id_name}' vs '#{other.target_type.id_name}'"}
      end
    when {Fn, Fn}
      if left.args.size != other.args.size
        return {false, "Function args count mismatch: #{left.args.size} vs #{other.args.size}"}
      end

      if left.vaarg != other.vaarg
        return {false, "Function vaarg mismatch: #{left.vaarg} vs #{other.vaarg}"}
      end

      left.args.size.times do |i|
        result, reason = left.args[i].structural_eq_with_reason?(other.args[i])
        return {false, "Function arg [#{i}] mismatch: #{reason}"} unless result
      end

      {true, "Functions are structurally equal"}
    when {IntType, IntType}
      if left.bytes_count != other.bytes_count
        return {false, "IntType bytes count mismatch: #{left.bytes_count} vs #{other.bytes_count}"}
      end

      if left.signed != other.signed
        return {false, "IntType signed mismatch: #{left.signed} vs #{other.signed}"}
      end

      {true, "IntTypes are structurally equal"}
    when {FloatType, FloatType}
      if left.bytes_count != other.bytes_count
        return {false, "FloatType bytes count mismatch: #{left.bytes_count} vs #{other.bytes_count}"}
      end

      {true, "FloatTypes are structurally equal"}
    when {BoolType, BoolType}
      {true, "BoolTypes are structurally equal"}
    when {VoidType, VoidType}
      {true, "VoidTypes are structurally equal"}
    else
      {false, "Incompatible type combination: #{left.class} and #{other.class}"}
    end
  end

  def structural_eq?(other : Type) : Bool
    result, reason = structural_eq_with_reason?(other)
    Myc.debug("type") { puts reason }
    result
  end
end
