class Myc::Backend::GM::BBVal < Myc::Backend::AbstractBBVal
  getter val : String

  def initialize(@val)
  end

  def to_s
    "gm(#{@val})"
  end
end
