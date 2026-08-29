record Myc::Location, filename : String, offset : UInt32 do
  protected def load_info(offset_in_bytes = false) : {Array(String), Int32, Int32}
    lines = File.read(filename).lines

    if offset_in_bytes
      current_offset = 0
      line_number = 0

      lines.each_with_index do |line, idx|
        if current_offset + line.bytesize > offset
          line_number = idx
          break
        end
        current_offset += line.bytesize + 1
      end

      line_content = lines[line_number]? || ""
      bytes_before = offset.to_i32 - current_offset

      line_position = if bytes_before <= 0
                        0
                      elsif bytes_before >= line_content.bytesize
                        line_content.size
                      else
                        String.new(line_content.to_slice[0, bytes_before]).size
                      end

      {lines, line_number, line_position}
    else
      current_offset = 0
      line_number = 0

      lines.each_with_index do |line, idx|
        if current_offset + line.size > offset
          line_number = idx
          break
        end
        current_offset += line.size + 1
      end

      line_position = offset.to_i32 - current_offset
      {lines, line_number, line_position}
    end
  end
end
