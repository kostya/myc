class Myc::Mycc::Error < Myc::Error
end

class Myc::Mycc::ClangError < Myc::Mycc::Error
  def print(io : IO)
    lines = @message.to_s.split("\n")
    io << "C source parse error: \n".colorize(:red)
    lines.each do |line|
      io << "  " << line.colorize(:yellow) << "\n"
    end
    io << "\n"
  end
end
