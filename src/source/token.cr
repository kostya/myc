abstract struct Myc::Source::Token
  property offset : UInt32 = 0
  record Eof < Token
  record Opcode < Token, code : Myc::Opcode::Code
  record OpcodeUnknown < Token, name : String

  abstract struct Value < Token
  end

  record IntValue < Value, val : Int64 | UInt64
  record BoolValue < Value, val : Bool
  record StringValue < Value, val : String
  record FloatValue < Value, val : Float64
end
