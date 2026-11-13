class Myc::Backend::GM::BBVal < Myc::Backend::AbstractBBVal
  getter val : LibGM::Value
  getter address : Bool

  def initialize(@val, @address = false)
  end

  def to_s
    "gm(#{@val.kind}:#{@val.index})"
  end
end
