class Myc::Backend::Value
  enum MM
    Val
    Ref

    def short_name
      case self
      in .val? then "val"
      in .ref? then "ref"
      end
    end
  end

  abstract struct PP
    def short_name
      case self
      in PP::Primitive      then "Co"
      in PP::Param          then "Pa"
      in PP::Global         then "Gl"
      in PP::GlobalConstant then "Gc"
      in PP::Local          then "Lo"
      in PP::CallResult     then "Ca"
      in PP::FnAddress      then "Fa"
      in PP::LabelAddress   then "La"
      in PP::Vla            then "Vl"
      in PP::Unknown, PP    then "??"
      end
    end

    record Unknown < PP
    record Primitive < PP
    record Param < PP, index : Int32
    record Global < PP, name : String
    record GlobalConstant < PP, name : String
    record Local < PP, name : String
    record CallResult < PP, name : String
    record FnAddress < PP, name : String
    record LabelAddress < PP, name : String
    record Vla < PP
  end

  getter bbval : AbstractBBVal
  getter type : Type
  getter mm : MM
  property pp : PP

  def initialize(@bbval, @type, @mm, @pp)
  end

  def val?
    @mm.val?
  end

  def ref?
    @mm.ref?
  end

  def unsafe_new_with_type(new_type : Type) : Value
    Value.new(@bbval, new_type, @mm, @pp)
  end
end
