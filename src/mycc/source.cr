class Myc::Mycc::Source
  getter filename : String
  getter content : String
  getter name : String

  def initialize(@filename)
    raise Exception.new("file not found `#{filename}`") unless File.exists?(filename)
    @content = File.read(filename)
    @name = File.basename(filename).gsub(/[^a-zA-Z0-9_]/, "_")
  end

  def clang_parse : Clang::TranslationUnit
    index = Clang::Index.new(false, false)
    files = [Clang::UnsavedFile.new(filename, content)]

    args = [
      "-x", "c",
      "-std=gnu11",
      "-I#{File.dirname(filename)}",
      "-Wno-implicit-function-declaration",
      "-D_FORTIFY_SOURCE=0",
    ] + FindIncludePaths.new.find

    if inc = ENV["MYCC_INCLUDE"]?
      inc.strip.split(",").each do |part|
        unless part.strip.empty?
          args << "-I"
          args << part
        end
      end
    end

    tu = Clang::TranslationUnit.from_source(index, files, args)

    if tu.has_errors?
      raise ClangError.new(tu.error_messages.join("\n"))
    end

    tu
  end

  def debug_ast(cursor : Clang::Cursor, indent = 0)
    return if skip_debug_ast?(cursor)
    puts "  " * indent + cursor.inspect
    cursor.visit_children do |child|
      debug_ast(child, indent + 1)
      Clang::ChildVisitResult::Continue
    end
  end

  private def skip_debug_ast?(cursor : Clang::Cursor)
    if location = cursor.location
      if filename = location.file_name
        return true if !filename.includes?(@filename)
      end
    end

    return true if cursor.kind == Clang::CursorKind::MacroDefinition && cursor.type.kind == Clang::TypeKind::Invalid
    false
  end
end
