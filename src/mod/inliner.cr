class Myc::Mod::Inliner
  getter mod : Mod
  getter inline_lib : Mod?

  def initialize(@mod, @inline_lib = nil)
  end

  def inline!
    inline_id = 0_u64
    inline_names = Set(String).new

    @mod.func_defs.each do |name, func_def|
      inline_names << name if func_def.inline_stats.can_inline
    end

    if lib1 = @inline_lib
      lib1.func_defs.each do |name, func_def|
        inline_names << name if func_def.inline_stats.can_inline
      end
    end

    while true
      any_inlined = false

      @mod.func_defs.each do |name, func_def|
        inline_stats = func_def.inline_stats
        inline_names.each do |inline_name|
          if inline_stats.calls[inline_name] > 0
            target = @mod.func_defs[inline_name]?
            if target && target.body
            else
              target = nil
            end

            unless target
              target = @inline_lib.try(&.func_defs[inline_name]?)
            end

            if target && target.body
              any_inlined = true
              r = Replacer.new(@mod, func_def, target, inline_id)
              r.replace!
              inline_id += 1
            end
          end
        end
      end

      break unless any_inlined
    end
  end

  class Stats
    getter can_inline : Bool
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
      @private_calls = false
      @can_inline = false
    end

    def can_inline? : Bool
      return false if @call_itself
      return false if @loop_count > 0
      return false if @switch_count > 0
      return false if @private_calls

      return false if @inst_count > 50
      return false if @inst_count == 0

      return false if @ret_count > 5 || @goto_count > 3 || @if_count > 0
      return true if @inst_count <= 10 && @if_count == 0
      return true if @inst_count <= 15 && @if_count <= 1 && @goto_count == 0
      return true if @inst_count <= 20 && @if_count == 0 && @call_count <= 1
      return true if @inst_count <= 45 && @if_count <= 1 && @call_count == 0 && @goto_count == 0

      false
    end

    def update(op : Opcode, mod : Mod)
      @inst_count += 1

      case op
      when Opcode::If
        @if_count += 1
      when Opcode::Loop
        @loop_count += 1
      when Opcode::Switch
        @switch_count += 1
      when Opcode::Goto, Opcode::Next, Opcode::Break
        @goto_count += 1
      when Opcode::Call
        @call_count += 1
        if op.name == @name
          @call_itself = true
        end
        @calls[op.name] += 1
        if f = mod.func_defs[op.name]?
          if f.attrs.includes?(Mod::FuncDef::Attr::Private)
            @private_calls = true
          end
        end
      when Opcode::Addr
        if (func_name = op.func_name) && (f = mod.func_defs[func_name]?)
          if f.attrs.includes?(Mod::FuncDef::Attr::Private)
            @private_calls = true
          end
        end
      when Opcode::Ret
        @ret_count += 1
      when Opcode::Global
        if g = mod.global_defs[op.name]?
          if g.private_flag
            @private_calls = true
          end
        end
      when Opcode::Stack, Opcode::Label, Opcode::Param, Opcode::Slot
        @inst_count -= 1
      end
    end

    def finish(func_def : FuncDef)
      if func_def.attrs.includes?(Mod::FuncDef::Attr::Private)
        @private_calls = true
      end
      if func_def.type_fn.vaarg || func_def.name == "main"
        @can_inline = false
        return
      end
      @can_inline = can_inline?
      if body = func_def.body
        if body.list.size > 0 && body.list.last.is_a?(Opcode::Ret)
          @ret_last = true
        end
      end
    end
  end

  class Replacer
    getter mod : Mod
    getter func_def : FuncDef
    getter inline_func_def : FuncDef
    getter inline_id : UInt64

    def initialize(@mod, @func_def, @inline_func_def, @inline_id)
      @inline_internal_id = 0_u64
    end

    def replace!
      body = func_def.body.not_nil!
      check(body)
    end

    def check(seq : Opcode::Seq)
      inline_name = inline_func_def.name
      list = seq.list
      inline_stats = @func_def.inline_stats
      pos = 0
      while pos < list.size
        op = list[pos]
        pos += 1
        case op
        when Opcode::Call
          if op.name == inline_name
            Myc.debug(:inliner) do
              puts "INLINE --------------- #{inline_name} into #{func_def.name} -----------------"
            end

            new_seq = get_dup_seq
            slots = [] of Opcode
            @inline_func_def.type_fn.args.size.times do |idx|
              slots << Opcode::To.new(@inline_func_def.type_fn.args[idx]).with_position(op)
              slots << Opcode::Slot.new("#{inline_prefix}_#{idx}").with_position(op)
            end

            new_list = [] of Opcode
            new_list += list[0...pos - 1] if pos > 1
            new_list += slots
            new_list += new_seq.list

            if @inline_func_def.inline_stats.@ret_count == 0
            elsif @inline_func_def.inline_stats.@ret_last && @inline_func_def.inline_stats.@ret_count == 1
            else
              if @inline_func_def.type_fn.ret.eq?(@mod.typer.void)
                new_list << Opcode::Label.new("#{inline_prefix}_end").with_position(op)
              else
                new_list << Opcode::Label.new("#{inline_prefix}_end").with_position(op)
                new_list << Opcode::Local.new("#{inline_prefix}_result", @inline_func_def.type_fn.ret).with_position(op)
              end
            end

            new_list += list[pos..-1]
            seq.list = new_list
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
          new_list << Opcode::Slot.new(
            slot_map[op.name]? || begin
              new_name = "#{inline_prefix}_#{op.name}"
              slot_map[op.name] = new_name
              new_name
            end
          ).with_position(op)
        when Opcode::Local
          new_list << Opcode::Local.new(
            local_map[op.name]? || begin
              new_name = "#{inline_prefix}_#{op.name}"
              local_map[op.name] = new_name
              new_name
            end,
            op.type
          ).with_position(op)
        when Opcode::Ret
          if @inline_func_def.inline_stats.@ret_count == 0
            raise "unreachable"
          elsif @inline_func_def.inline_stats.@ret_last && @inline_func_def.inline_stats.@ret_count == 1
            unless @inline_func_def.type_fn.ret.eq?(@mod.typer.void)
            end
          else
            if @inline_func_def.type_fn.ret.eq?(@mod.typer.void)
              new_list << Opcode::Goto.new("#{inline_prefix}_end").with_position(op)
            else
              new_list << Opcode::Local.new("#{inline_prefix}_result", @inline_func_def.type_fn.ret).with_position(op)
              new_list << Opcode::Store.new.with_position(op)
              new_list << Opcode::Goto.new("#{inline_prefix}_end").with_position(op)
            end
          end
        when Opcode::Param
          new_list << Opcode::Slot.new("#{inline_prefix}_#{op.index}").with_position(op)
        when Opcode::If
          new_list << Opcode::If.new(
            _get_dup_seq(op.then_seq, local_map, slot_map),
            _get_dup_seq(op.else_seq, local_map, slot_map)
          ).with_position(op)
        when Opcode::Loop
          new_list << Opcode::Loop.new(
            _get_dup_seq(op.init_seq, local_map, slot_map),
            _get_dup_seq(op.cond_seq, local_map, slot_map).with_stack_balance(1),
            _get_dup_seq(op.body_seq, local_map, slot_map),
            _get_dup_seq(op.step_seq, local_map, slot_map),
          ).with_position(op)
        when Opcode::Switch
          new_list << Opcode::Switch.new(
            op.cases_seq.map { |seq| _get_dup_seq(seq, local_map, slot_map) },
            op.values,
            _get_dup_seq(op.else_seq, local_map, slot_map),
          ).with_position(op)
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
