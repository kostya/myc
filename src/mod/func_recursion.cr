class Myc::Mod
  def check_func_recursion!(header_mod : Mod)
    detector = RecursionDetector.new(self, header_mod)
    detector.detect.each do |name|
      if f = self.func_defs[name]?
        f.inline_stats.recursive!
      end
    end
  end

  class RecursionDetector
    def initialize(@mod : Mod, @header_mod : Mod)
      @visited = Set(String).new
      @in_stack = Set(String).new
      @recursive = Set(String).new
    end

    def detect : Set(String)
      @mod.func_defs.each_key do |name|
        dfs(name) unless @visited.includes?(name)
      end
      @recursive
    end

    private def dfs(name : String) : Bool
      return true if @in_stack.includes?(name)
      return false if @visited.includes?(name)

      @in_stack << name
      @visited << name

      if (func = @mod.func_defs[name]?) || (func = @header_mod.func_defs[name]?)
        func.inline_stats.calls.each_key do |called|
          if dfs(called)
            @recursive << called
            return true
          end
        end
      end

      @in_stack.delete(name)
      false
    end
  end
end
