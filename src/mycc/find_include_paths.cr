class Myc::Mycc::FindIncludePaths
  def initialize
    @paths = [] of String
    @cc = ENV["CC"]? || ENV["cc"]? || "clang"
  end

  class Error < Exception; end

  def find : Array(String)
    return @paths unless @paths.empty?

    find_from_compiler
    add_macos_sdk
    find_gcc_paths
    find_fallback
    add_custom_paths
    remove_duplicates

    @paths
  end

  private def find_from_compiler
    output = `#{@cc} -E -v -xc /dev/null 2>&1`
    output = `gcc -E -v -xc /dev/null 2>&1` unless $?.success?

    return unless $?.success?

    if match = output.match(/#include <\.\.\.> search starts here:\n(.*?)\nEnd of search list\./m)
      match[1].strip.each_line do |line|
        path = line.strip.gsub(/\s*\([^)]*\)\s*$/, "").strip
        next if path.empty? || !Dir.exists?(path)

        if path.includes?("Frameworks") || path.ends_with?(".framework")
          @paths << "-iframework" << path
        else
          @paths << "-isystem" << path
        end
      end
    end
  rescue
  end

  private def find_gcc_paths
    gcc_include = `gcc -print-file-name=include 2>/dev/null`.strip
    if !gcc_include.empty? && Dir.exists?(gcc_include)
      @paths << "-isystem" << gcc_include
    end

    Dir.glob("/usr/lib/gcc/*/*/include").each do |path|
      @paths << "-isystem" << path if Dir.exists?(path)
    end
  rescue
  end

  private def find_fallback
    paths = [
      "/usr/include",
      "/usr/local/include",
      "/opt/homebrew/include",
      "/usr/include/x86_64-linux-gnu",
      "/usr/include/aarch64-linux-gnu",
      "/usr/include/i386-linux-gnu",
    ]

    paths.each do |path|
      @paths << "-isystem" << path if Dir.exists?(path)
    end
  end

  private def add_macos_sdk
    sdk = `xcrun --show-sdk-path 2>/dev/null`.strip
    return if sdk.empty? || !Dir.exists?(sdk)
    return if @paths.any? { |a| a == "-isysroot" }

    @paths.unshift("-isysroot", sdk)
  end

  private def add_custom_paths
    if custom = ENV["MYCC_INCLUDE"]?.presence
      @paths << "-I" << custom if Dir.exists?(custom)
    end
  end

  private def remove_duplicates
    result = [] of String
    seen = Set(String).new
    i = 0

    while i < @paths.size
      item = @paths[i]

      if (item == "-I" || item == "-isystem" || item == "-iframework" || item == "-isysroot") && i + 1 < @paths.size
        flag = item
        path = @paths[i + 1]
        key = "#{flag}:#{path}"

        unless seen.includes?(key)
          seen << key
          result << flag << path
        end
        i += 2
      else
        unless seen.includes?(item)
          seen << item
          result << item
        end
        i += 1
      end
    end

    @paths = result
  end
end
