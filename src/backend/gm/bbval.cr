class Myc::Backend::GM::BBVal < Myc::Backend::AbstractBBVal
  getter val : LibGM::Value

  def initialize(@val)
  end

  def to_s
    "gm(#{@val.kind}:#{@val.index})"
  end
end
