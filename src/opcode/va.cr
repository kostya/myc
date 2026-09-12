class Myc::Opcode::Va < Myc::Opcode
  enum Op
    Start
    Arg
    End
    Copy
  end

  getter op : Op
  getter type : Type?

  def initialize(@op, @type)
  end
end
