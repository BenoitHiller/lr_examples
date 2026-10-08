require_relative 'digraph'

module LrExamples
  ActionTable2 = Struct.new(
    :packed,
    :check,
    :base,
    :base_goto,
    :default_reductions,
    :default_gotos,
    :invalid_base,
    :tokens,
    :non_terminal_base
  ) do
    def report_print(rp)
      rp.multiline do
        rp.write("Index\tPacked")
        packed.each_with_index do |entry, i|
          rp.inline("\t") do
            rp.rp(i)
            rp.rp(entry)
          end
        end
        rp.write("Index\tBase\tCheck\tDefault")
        base.each_with_index do |entry, i|
          rp.inline("\t") do
            rp.rp(i)
            rp.rp(entry)
            rp.rp(check[i])
            rp.rp(default_reductions[i])
          end
        end
        rp.write("Base\tDefault\tToken")
        base_goto.each_with_index do |entry, i|
          rp.inline("\t") do
            rp.rp(entry)
            rp.rp(default_gotos[i])
            rp.rp(tokens.inverted[i + non_terminal_base])
          end
        end
      end
    end
  end

  class ActionTable
    def initialize(tokens, actions, non_terminals)
      @tokens = tokens
      @non_terminals = non_terminals

=begin
      @order = BiHash.new
      @order.update(self.initial_order(actions).each_with_index.to_h)
=end

      @state_count = actions.length
      @non_terminal_base = @non_terminals.min
      @size = @state_count + @non_terminals.length

      @table = []
      actions.each_with_index.each do |entries, state|
        entries.each do |token, action|
          self.set_action(state, token, action)
        end
      end

      @defaults = Array.new(@table.length, 0)
      @table.each_with_index.each do |row, i|
        unless row
          next
        end
        values = row.values
        if i < @state_count
          values = values.filter { |n| n < 0 }.map { |n| -n }
        end
        action, _ = values.tally.each.max_by(&:last)
        if action
          @defaults[i] = action
        end
      end

      @vectors = Array.new(@table.length)
      @table.each_with_index.each do |row, i|
        unless row
          next
        end

        default = @defaults[i]
        if i < @state_count
          default = -default
        end
        remaining = row.filter { |_, action| action != default }
        unless remaining.empty?
          @vectors[i] = remaining.each.sort_by(&:first).to_a.transpose
        end
      end

      order = (0...@vectors.length).to_a
      order.sort_by! do |i|
        vector = @vectors[i]
        if vector
          [vector[0][-1] - vector[0][0], vector[0].length]
        else
          [-1, 0]
        end
      end

      # A value more negative than the minimum that can be in the
      # packed table.
      @default_base = -@state_count
      @packed = []
      @check = []
      @base = Array.new(@size)
      order.each_with_index.each do |n, index|
        vector = @vectors[n]
        unless vector && !vector[0].empty?
          next
        end
        match = order[...index].find do |other_n|
          other_vector = @vectors[other_n]
          vector == other_vector
        end

        if match
          @base[n] = @base[match]
        else
          base = -vector[0][0]

          while base < @packed.length
            if vector[0].all? do |from|
              !@packed[base + from]
            end
              break
            end
            base += 1
          end

          @base[n] = base

          (0...(vector[0].length)).each do |i|
            from = vector[0][i]
            to = vector[1][i]

            @packed[base + from] = to
            @check[base + from] = from
          end
        end
      end
      @base.map! { |value| value.nil? ? @default_base : value }
      @packed.map! { |value| value.nil? ? 0 : value }
      @check.map! { |value| value.nil? ? -1 : value }
    end

    def report_print(rp)
      rp.multiline(indent: 0) do
        rp.rp(@tokens)
        rp.write("T-Table")
        rp.inline("\t") do
          rp.write("State")
          terminals.each do |_, token|
            rp.rp(token)
          end
        end
        @state_count.times.each do |state|
          row = @table[state]
          rp.inline("\t") do
            rp.write(state)
            terminals.each do |token, _|
              action = row&.[](token)
              if action
                rp.rp(action)
              else
                rp.write("")
              end
            end
          end
        end
        rp.write("N-Table")
        states = n_table.compact.flat_map do |entries|
          entries.keys
        end.to_set.to_a.sort
        rp.inline("\t") do
          rp.write("State")
          states.each do |state|
            rp.rp(state)
          end
        end
        non_terminals.each do |token, label|
          row = @table[token_index(token)]
          rp.inline("\t") do
            rp.rp(label)
            states.each do |state|
              action = row&.[](state)
              if action
                rp.rp(action)
              else
                rp.write("")
              end
            end
          end
        end
        rp.write("State\tBase\tDefault")
        @state_count.times.each do |state|
          rp.inline("\t") do
            rp.rp(state)
            rp.rp(@base[state])
            rp.rp(@defaults[state])
          end
        end

        rp.write("Index\tPacked\tCheck")
        @packed.each_with_index do |entry, i|
          rp.inline("\t") do
            rp.rp(i)
            rp.rp(entry)
            rp.rp(@check[i])
          end
        end
        rp.write("Token\tBase\tDefault")
        (@state_count...@size).each do |i|
          token = i - @state_count + @non_terminal_base
          rp.inline("\t") do
            rp.rp(@tokens[token])
            rp.rp(@base[i])
            rp.rp(@defaults[i])
          end
        end
      end
    end

    def sort_non_terminals_first!
      order = @actions.length.times.to_a
      order.sort_by! do |state|
        [
          (@non_terminals & @actions[state].keys).empty? ? 1 : 0,
          state
        ]
      end
      to_order = order.each_with_index.to_h
      @actions = @actions.map do |row|
        row.transform_values do |action|
          if action >= 0
            to_order[action]
          else
            action
          end
        end
      end
      @actions = order.map { |i| @actions[i] }
    end

    private def initial_order(actions)
      order = actions.length.times.to_a
      order.sort_by! do |state|
        [
          (@non_terminals & actions[state].keys).empty? ? 1 : 0,
          state
        ]
      end
    end

    private def non_terminals
      @tokens.filter { |value, _| @non_terminals.include?(value) }
    end

    private def terminals
      @tokens.filter { |value, _| !@non_terminals.include?(value) }
    end

    private def set_action(state, token, action, re_order: false)
      if re_order
        state = @order[state]
        if action >= 0
          action = @order[action]
        end
      end

      if @non_terminals.include?(token)
        location = token_index(token)
        @table[location] ||= {}
        @table[location][state] = action
      else
        @table[state] ||= {}
        @table[state][token] = action
      end
    end

    private def token_index(token)
      token - @non_terminal_base + @state_count
    end

    private def n_table
      @table[@state_count..-1]
    end

    def self.from_gotos(
      tokens,
      non_terminals,
      states,
      gotos,
      reductions
    )
      tokens = tokens.inverted
      actions = Array.new(states) { Hash.new }

      gotos.each do |state, entry|
        entry.each do |token, action|
          actions[state][token] = action
        end
      end
      reductions.each do |state, entry|
        entry.each do |token, production|
          actions[state][token] = -(production.first)
        end
      end

      new(tokens, actions, non_terminals)
    end
  end

  class Lalr < Lr0
    include Digraph
    using CoreExtensions

    Edge = Data.define(:from, :label) do
      def format(parser)
        "[#{from}, #{parser.tokens.inverted[label]}]"
      end
    end

    memoized def direct_reads
      direct_reads = Hash.with_default(Set)

      transitions.each do |edge, next_state|
        if non_terminals.include?(edge.label)
          direct_reads[edge] = terminals & next0[next_state].keys
        end
      end

      direct_reads
    end

    memoized :frozen, def reads_relation
      # Note that it is important that the reads_relation returns an
      # empty value and not nil for undefined edges.
      reads = Hash.with_default(Set)

      transitions.each do |edge, next_state|
        if non_terminals.include?(edge.label)

          next0[next_state].keys.each do |next_token|
            if nullable_tokens.include?(next_token)
              reads[edge].add(Edge[next_state, next_token])
            end
          end
        end
      end

      reads
    end

    memoized :frozen, def reads
      digraph(reads_relation, transitions.keys, &direct_reads)
    end

    memoized def transitions
      next0.flat_map do |start_state, state_transitions|
        state_transitions.map do |token, next_state|
          [Edge[start_state, token], next_state]
        end
      end.to_h
    end

    memoized def non_terminal_transitions
      transitions.filter do |edge, _|
        non_terminals.include?(edge.label)
      end
    end

    memoized def accessing_edges
      accessing_edges = Hash.with_default(Set)

      transitions.each do |edge, state|
        accessing_edges[state].add(edge)
      end

      accessing_edges
    end

    # The lookback and includes relations can be computed efficiently
    # at the same time because they both involve the same traversal of
    # paths defined by the tokens in some production.
    def compute_path_relations
      @lookback_relation = Hash.with_default(Set)
      @includes_relation = Hash.with_default(Set)

      non_terminal_transitions.each do |edge, _|
        (productions_for[edge.label]).each do |production|
          tokens = tokens_for(production)
          state = edge.from
          included = Set.new

          tokens.each do |token|
            next_edge = Edge[state, token]
            state = transitions[next_edge]
            if state.nil?
              # if we don't find a transition for a given token along
              # the path described by the production, then state will
              # be nil here and that value will be available outside
              # the loop as a flag indicating whether the path was
              # found.
              break
            end

            # If we find a path from the initial state, then the
            # transitions which include the start state are those for
            # the nullable non-terminals at the end of the path, and
            # at most one non-nullable non-terminal that immediately
            # proceeds those.
            if non_terminals.include?(token)
              unless nullable_tokens.include?(token)
                included.clear
              end

              included.add(next_edge)
            else
              included.clear
            end
          end

          unless state.nil?
            # TODO: do we need to verify the final edge has the
            # reduction, or is it required to?
            @lookback_relation[Edge[state, production]].add(edge)
            included.each do |other_edge|
              @includes_relation[other_edge].add(edge)
            end
          end
        end
      end

      @includes_relation.freeze
      @lookback_relation.freeze
    end

    def includes_relation
      unless defined? @includes_relation
        compute_path_relations
      end
      @includes_relation
    end

    def lookback_relation
      unless defined? @lookback_relation
        compute_path_relations
      end
      @lookback_relation
    end

    memoized def follow
      digraph(
        includes_relation,
        non_terminal_transitions.keys,
        &reads
      )
    end

    memoized def lookahead
      lookahead = Hash.with_default(Set)

      lookback_relation.each do |from_edge, to_edges|
        to_edges.each do |edge|
          lookahead[from_edge] += follow[edge]
        end
      end

      lookahead
    end

    memoized def reduce
      reduce = Hash.with_default { Hash.with_default(Set) }

      lookahead.each do |edge, tokens|
        edge => Edge[state, production]
        if reduce0[state].include?(production)
          tokens.each do |token|
            reduce[state][token].add(production)
          end
        end
      end

      reduce
    end

    def action_table
      ActionTable.from_gotos(
        @tokens,
        non_terminals,
        @table_states.length,
        @next0,
        reduce
      )
    end

    def to_table
      output = []
      output << @tokens.length.times.map { |i|
        @tokens.inverted[i]
      }.to_a
      @table_states.each do |_, state|
        shifts = @next0[state]
        reduces = reduce[state].transform_values { |n| -n.first }
        row = Array.new(@tokens.length)
        @tokens.length.times do |i|
          row[i] = shifts[i] || reduces[i]
        end
        output << row
      end
      output
    end

    def to_table2
      output1 = []
      output1 << terminals.map { |i|
        @tokens.inverted[i]
      }.to_a
      order = @table_states.length.times.to_a
      order.sort_by! do |i|
        tokens = @next0[i].keys
        [(non_terminals & tokens).empty? ? 1 : 0, i]
      end
      to_order = order.each_with_index.to_h

      @table_states.length.times.each do |i|
        state = order[i]
        shifts = @next0[state]
        reduces = reduce[state].transform_values { |n| -n.first }
        row = Array.new(@tokens.length)
        terminals.length.times do |i|
          row[i] = to_order[shifts[i]] || reduces[i]
        end
        output1 << row
      end

      non_terminals = ((@terminals_count + 1)..@tokens.length).to_a

      output2 = []
      output2 << non_terminals.map { |i|
        @tokens.inverted[i]
      }.to_a

      @table_states.length.times.each do |i|
        state = order[i]
        shifts = @next0[state].slice(*non_terminals)
        if shifts.empty?
          break
        end
        row = []
        non_terminals.each do |token|
          row << to_order[shifts[token]]
        end
        output2 << row
      end

      [output1, output2]
    end

    def pack_tables
      mappings = @next0.clone
      reduce.each do |state, actions|
        actions.each do |token, productions|
          if productions.length > 1
            raise "r/r conflict found in #{state}"
          end
          if mappings[state].key?(token)
            raise "s/r conflict found in #{state}"
          end
          mappings[state][token] = -(productions.first)
        end
      end

      state_count = @table_states.length

      # Separate out the non-terminal actions and place them at the
      # end of the mappings list, with state and token transposed.
      #
      # Note we also explicitly iterate over a copy of keys here
      # because we are tacking on stuff at the end of the mappings
      # while we iterate and we don't want to consider those.
      mappings.keys.each do |state|
        actions = mappings[state]
        non_terminal_keys = non_terminals & actions.keys
        non_terminal_keys.each do |token|
          index = token + state_count - @terminals_count
          mappings[index][state] = actions.delete(token)
        end
      end

      rp mappings

      widths = mappings.transform_values do |_, actions|
        if actions && !actions.empty?
          actions.keys.max - actions.keys.min
        else
          -1
        end
      end

      default_reductions = {}
      default_gotos = {}
      mappings.each do |index, actions|
        values = actions.values
        if index < @table_states.length
          # for the normal actions we only consider the default
          # reductions, while for the gotos we are looking for a state
          # number instead.
          values = values.filter { |action| action < 0 }
        end
        if values.empty?
          next
        end
        # tally counts the number of occurrences of each value
        counts = values.tally

        default = counts.each.max_by { |_, count| count }[0]

        actions.delete_if { |_, value| value == default }

        if index < @table_states.length
          # Flip the sign now so that the parser doesn't have to do it
          # on every reduction.
          default_reductions[index] = -default
        else
          default_gotos[index] = default
        end
      end

      # Generate an order to pack the entries into the table in, based
      # on the width of the space they will take up in the resulting
      # table, and how many entries they contain.
      order = mappings.keys.sort_by do |index|
        actions = mappings[index]

        if actions && !actions.empty?
          # TODO: The width used needs to be from before removing the
          # default. This is because the code will still attempt to
          # fetch values at base + default_key locations, if we don't
          # consider this when picking a base that could result in
          # attempting to read from a negative index.
          [widths[index], actions.length]
        else
          [-1, 0]
        end
      end.reverse

      base = {}
      packed = []
      check = []
      order.each_with_index do |index, sort_index|
        actions = mappings[index]
        if actions.empty?
          next
        end
        matching_index = order[0...sort_index].find do |other_index|
          # If there is already a set of actions in the table that
          # will work for the current index we can reuse that.
          mappings[other_index] == actions
        end

        # The break exited the inner loop, so we check if it succeeded
        # to see if we can skip the rest of this iteration.
        if matching_index
          base[index] = base[matching_index]
          next
        end

        location = -(actions.keys.min)
        while location < packed.length
          can_place_here = actions.keys.all? do |key|
            # If there is an available space in the table
            # corresponding to every key, given the current candidate
            # base value.
            packed[location + key].nil?
          end

          if can_place_here
            break
          else
            location += 1
          end
        end

        base[index] = location
        actions.each do |key, action|
          key_location = location + key
          packed[key_location] = action
          check[key_location] = key
        end
      end

      # Now split out the goto bases like we did for the defaults,
      # again just to save a bit of math in the actual parser turning
      # a token number into a key.
      base_goto = {}

      non_terminals.length.times do |i|
        key = @table_states.length + i
        if base.key?(key)
          base_goto[i - 1] = base.delete(key)
        end
      end

      # Finally fix everything up by filling in default values in the
      # empty entries and turning the remaining hashmaps into simple
      # arrays.

      # In the main table 0 indicates that the default should be used
      packed.map! { |value| value || 0 }

      # Compute an unused base number to use to mark invalid bases
      invalid_base = [base.values.min, base_goto.values.min].min - 1

      base = Array.new(@table_states.length) do |i|
        base.fetch(i, invalid_base)
      end

      # In the check table a 0 entry is technically valid, for a goto
      # from state 0, so we use -1 to mark invalid values.
      check = Array.new(base.length) do |i|
        value = check[i]
        if value.nil?
          -1
        else
          value
        end
      end

      base_goto = Array.new(non_terminals.length) do |i|
        base_goto.fetch(i, invalid_base)
      end

      default_reductions = Array.new(@table_states.length) do |i|
        default_reductions.fetch(i, 0)
      end

      default_gotos = Array.new(base_goto.length) do |i|
        default_gotos.fetch(
          i + @table_states.length + 1,
          invalid_base
        )
      end

      ActionTable2.new(
        packed: packed,
        check: check,
        base: base,
        base_goto: base_goto,
        default_reductions: default_reductions,
        default_gotos: default_gotos,
        invalid_base: invalid_base,
        tokens: @tokens,
        non_terminal_base: non_terminals.min
      )
    end

    def report_print(rp)
      rp.write_header(self)
      rp.multiline do
        rp.write_instance_variables(self, [:@tokens])

        rp.inline do
          rp.write("States", color: :bright_cyan)
          rp.multiline(
            after: rp.color("end", :bright_blue),
            separator: "\n"
          ) do
            @table_states.each do |items, state|
              rp.inline(" ") do
                rp.write("state")
                rp.rp(state)
              end
              rp.multiline do
                items.each do |current|
                  rp.inline(" ") do
                    rp.write("[")
                    production = item_production(current)
                    rp.rp(
                      @tokens.inverted[@production_tokens[production]]
                    )
                    rp.write("->")
                    production_items(production).each do |item|
                      token = @items[item]
                      if item == current
                        rp.write(".")
                      end
                      rp.rp(tokens.inverted[token])
                    end
                    if @items[current] <= 0
                      rp.write(".")
                    end

                    rp.write("]")
                  end
                end
              end
              rp.multiline do
                rp.write("")
                rp.write("Actions:")

                (@next0[state]).each do |token, next_state|
                  rp.inline(" ") do
                    rp.write("shift")
                    rp.rp(@tokens.inverted[token])
                    rp.write("to")
                    rp.rp(next_state)
                  end
                end
              end
              rp.multiline do
                (reduce[state]).each do |token, productions|
                  productions.each do |production|
                    rp.inline(" ") do
                      rp.write("reduce")
                      rp.rp(@tokens.inverted[token])
                      rp.write("with")
                      rp.rp(production)
                    end
                  end
                end
              end
            end
          end
        end
      end
      rp.write("end", color: :bright_blue)
    end
  end
end
