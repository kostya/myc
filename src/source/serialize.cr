class Myc::Source::Serialize
  ANNOTATION_COLUMN = 20

  getter root : Node
  getter io : IO

  def initialize(@root, @io)
  end

  def serialize
    if @root.code == Opcode::Code::MOD
      @root.as(Node::Container).sections.each do |s|
        serialize_node(s, 0)
        io << '\n'
      end
    else
      serialize_node(@root, 0)
    end
  end

  protected def serialize_node(node : Node, indent : Int32)
    serialize_node_header(node, indent)
    serialize_node_body(node, indent + 1)
    serialize_node_footer(node, indent)
  end

  protected def serialize_node_header(node : Node, indent : Int32)
    if c = node.comment
      line = String.build do |s|
        _serialize_node_header(s, node, indent)
      end
      io << line

      pad = ANNOTATION_COLUMN - line.size - indent * 2
      pad = 1 if pad < 1
      padding(pad)
      io << c
    else
      _serialize_node_header(io, node, indent)
    end

    io << "\n"
  end

  protected def _serialize_node_header(io : IO, node : Node, indent : Int32)
    padding(indent * 2)
    node.code.to_s(io)

    node.values.try &.each_with_index do |value, index|
      io << ' '
      format_value(value, io)
    end
  end

  protected def serialize_node_body(node : Node::Container, indent : Int32)
    node.sections.each { |s| serialize_node(s, indent) }
  end

  protected def serialize_node_body(node : Node::Sequence, indent : Int32)
    node.list.each { |op| serialize_node(op, indent) }
  end

  protected def serialize_node_body(node : Node, indent : Int32)
  end

  protected def serialize_node_footer(node : Node::Opcode, indent : Int32)
  end

  protected def serialize_node_footer(node : Node, indent : Int32)
    if close_code = CLOSE_OPCODES[node.code]?
      padding(indent * 2)
      io << close_code.to_s << "\n"
    end
  end

  private def padding(pad)
    pad.times { io << ' ' }
  end

  private def format_value(v : Token::Value, io : IO)
    case v
    when Token::StringValue
      v = v.val
      if v.empty? || Tokenizer::SEPARATOR.any? { |sep| v.includes?(sep) } || v.includes?('\\')
        v.inspect(io)
      else
        io << ':'
        io << v
      end
    else
      io << v.val
    end
  end
end
