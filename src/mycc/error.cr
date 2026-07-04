class Myc::Mycc::Error < Myc::Error
end

class Myc::Mycc::ClangError < Myc::Mycc::Error
  def print(io : IO)
  end
end
