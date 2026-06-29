class Myc::Type::Fn < Myc::Type
  getter args : Array(Type)
  getter ret : Type
  getter vaarg : Bool

  def initialize(@args, @ret, @vaarg = false)
    @id_name = String.build do |io|
      io << "fn<"
      @args.each_with_index do |type, index|
        io << ", " if index != 0
        io << type.id_name
      end
      if @args.any? && @vaarg
        io << ", ..."
      end
      io << ", " if @args.any?
      io << @ret.id_name
      io << '>'
    end

    @backend_name = normalize_name(@id_name)
  end

  def inspect(io)
    io << id_name
  end
end
