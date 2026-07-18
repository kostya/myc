class Myc::Mod::Inliner
  getter mod : Mod

  def initialize(@mod)
  end

  def calc_stats
    @mod.func_defs.each_value do |func_def|
      if body = func_def.body
        func_def.inline_stats.run(body)
      end
    end
  end

  def inline!
    inline_id = 0_u64
    inline_names = Set(String).new
    @mod.func_defs.each do |name, func_def|
      inline_names << name if func_def.inline_stats.can_inline
    end

    while true
      any_inlined = false

      @mod.func_defs.each do |name, func_def|
        inline_stats = func_def.inline_stats
        inline_names.each do |inline_name|
          if inline_stats.calls[inline_name] > 0
            any_inlined = true
            r = Replacer.new(mod, func_def, mod.func_defs[inline_name], inline_id)
            r.replace!
            inline_id += 1
          end
        end
      end

      break unless any_inlined
    end
  end

  class Stats
    property can_inline = false
    property calls = Hash(String, Int32).new(0)
    getter name : String

    def initialize(@name)
      @if_count = 0
      @switch_count = 0
      @loop_count = 0
      @call_count = 0
      @call_itself = false
      @inst_count = 0
      @goto_count = 0
      @ret_count = 0
      @ret_last = false
    end

    def run(body)
      check(body)
      @can_inline = can_inline?
      if body.list.size > 0 && body.list.last.is_a?(Opcode::Ret)
        @ret_last = true
      end
    end

    def can_inline? : Bool
      return false if @call_itself
      return false if @loop_count > 0
      return false if @switch_count > 0

      return false if @inst_count > 50
      return false if @inst_count == 0

      return false if @ret_count > 5 || @goto_count > 3 || @if_count > 0

      return true if @inst_count <= 10 && @if_count == 0

      return true if @inst_count <= 15 && @if_count <= 1 && @goto_count == 0

      return true if @inst_count <= 20 && @if_count == 0 && @call_count <= 1

      return true if @inst_count <= 45 && @if_count <= 1 && @call_count == 0 && @goto_count == 0

      false
    end

    private def check(seq : Opcode::Seq)
      seq.list.each do |op|
        @inst_count += 1

        case op
        when Opcode::If
          @if_count += 1
          check(op.then_seq)
          check(op.else_seq)
        when Opcode::Loop
          @loop_count += 1
          check(op.init_seq)
          check(op.cond_seq)
          check(op.body_seq)
          check(op.step_seq)
        when Opcode::Switch
          @switch_count += 1
          op.cases_seq.each { |seq| check(seq) }
          check(op.else_seq)
        when Opcode::Goto, Opcode::Next, Opcode::Break
          @goto_count += 1
        when Opcode::Call
          @call_count += 1
          if op.name == @name
            @call_itself = true
          end
          @calls[op.name] += 1
        when Opcode::Ret
          @ret_count += 1
        when Opcode::Stack, Opcode::Label, Opcode::Param, Opcode::Slot
          @inst_count -= 1
        end
      end
    end
  end

  class Replacer
    getter mod : Mod
    getter func_def : FuncDef
    getter inline_func_def : FuncDef
    getter inline_id : UInt64
    getter verbose : Bool

    def initialize(@mod, @func_def, @inline_func_def, @inline_id)
      @inline_internal_id = 0_u64
      @verbose = ENV["MYC_INLINER_VERBOSE"]? == "1"
    end

    def replace!
      body = func_def.body.not_nil!
      check(body)
    end

    def check(seq : Opcode::Seq)
      inline_name = inline_func_def.name
      inline_stats = @func_def.inline_stats
      list = seq.list
      pos = 0_u64
      length = seq.list.size
      while pos < length
        op = seq.list[pos]
        pos += 1
        case op
        when Opcode::Call
          if op.name == inline_name
            if verbose
              puts "INLINE --------------- #{inline_name} into #{func_def.name} -----------------"
            end

            new_seq = get_dup_seq
            slots = [] of Opcode
            @inline_func_def.type_fn.args.size.times do |idx|
              slots << Opcode::To.new(@inline_func_def.type_fn.args[idx])
              slots << Opcode::Slot.new("#{inline_prefix}_#{idx}")
            end

            new_list = [] of Opcode
            new_list += list[0...pos - 1] if pos > 1
            new_list += slots
            new_list += new_seq.list

            if @inline_func_def.inline_stats.@ret_count == 0
            elsif @inline_func_def.inline_stats.@ret_last && @inline_func_def.inline_stats.@ret_count == 1
              if @inline_func_def.type_fn.ret.eq?(@mod.typer.void)
              else
              end
            else
              if @inline_func_def.type_fn.ret.eq?(@mod.typer.void)
                new_list << Opcode::Label.new("#{inline_prefix}_end")
              else
                new_list << Opcode::Label.new("#{inline_prefix}_end")
                new_list << Opcode::Local.new("#{inline_prefix}_result", @inline_func_def.type_fn.ret)
              end
            end

            new_list += list[pos..-1]

            list = new_list
            seq.list = list
            pos += new_seq.list.size + slots.size
            inline_stats.calls[inline_name] -= 1
            @inline_internal_id += 1
          end
        when Opcode::If
          check(op.then_seq)
          check(op.else_seq)
        when Opcode::Loop
          check(op.init_seq)
          check(op.cond_seq)
          check(op.body_seq)
          check(op.step_seq)
        when Opcode::Switch
          op.cases_seq.each { |seq| check(seq) }
          check(op.else_seq)
        end
      end
    end

    def get_dup_seq : Opcode::Seq
      local_map = Hash(String, String).new
      slot_map = Hash(String, String).new
      _get_dup_seq(@inline_func_def.body.not_nil!, local_map, slot_map)
    end

    def _get_dup_seq(seq : Opcode::Seq, local_map, slot_map) : Opcode::Seq
      return seq if seq.list.empty?

      new_list = [] of Opcode
      seq.list.each do |op|
        case op
        when Opcode::Slot
          if l = slot_map[op.name]?
            new_list << Opcode::Slot.new(l)
          else
            new_name = "#{inline_prefix}_#{op.name}"
            slot_map[op.name] = new_name
            new_list << Opcode::Slot.new(new_name)
          end
        when Opcode::Local
          if l = local_map[op.name]?
            new_list << Opcode::Local.new(l, op.type)
          else
            new_name = "#{inline_prefix}_#{op.name}"
            local_map[op.name] = new_name
            new_list << Opcode::Local.new(new_name, op.type)
          end
        when Opcode::Ret
          if @inline_func_def.inline_stats.@ret_count == 0
            raise "unreachable"
          elsif @inline_func_def.inline_stats.@ret_last && @inline_func_def.inline_stats.@ret_count == 1
            if @inline_func_def.type_fn.ret.eq?(@mod.typer.void)
            else
            end
          else
            if @inline_func_def.type_fn.ret.eq?(@mod.typer.void)
              new_list << Opcode::Goto.new("#{inline_prefix}_end")
            else
              new_list << Opcode::Local.new("#{inline_prefix}_result", @inline_func_def.type_fn.ret)
              new_list << Opcode::Store.new
              new_list << Opcode::Goto.new("#{inline_prefix}_end")
            end
          end
        when Opcode::Param
          new_list << Opcode::Slot.new("#{inline_prefix}_#{op.index}")
        when Opcode::If
          new_list << Opcode::If.new(
            _get_dup_seq(op.then_seq, local_map, slot_map),
            _get_dup_seq(op.else_seq, local_map, slot_map)
          )
        when Opcode::Loop
          new_list << Opcode::Loop.new(
            _get_dup_seq(op.init_seq, local_map, slot_map),
            _get_dup_seq(op.cond_seq, local_map, slot_map),
            _get_dup_seq(op.body_seq, local_map, slot_map),
            _get_dup_seq(op.step_seq, local_map, slot_map),
          )
        when Opcode::Switch
          new_list << Opcode::Switch.new(
            op.cases_seq.map { |seq| _get_dup_seq(seq, local_map, slot_map) },
            op.values,
            _get_dup_seq(op.else_seq, local_map, slot_map),
          )
        else
          new_list << op
        end
      end
      new_seq = Opcode::Seq.new
      new_seq.list = new_list
      new_seq
    end

    def inline_prefix
      "__#{@inline_func_def.name}_#{@inline_id}_#{@inline_internal_id}"
    end
  end
end
