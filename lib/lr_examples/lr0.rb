module LrExamples
  class Lr0
    attr_reader :tokens, :items, :next, :reduce

    def initialize(productions)
      #####################
      # Initialize Tokens #
      #####################

      # Compute which are non-terminals first as the only thing that
      # distinguishes the two is whether or not the token appears on
      # the left-hand-side of a production.
      non_terminals = {}
      productions.each do |left, _|
        unless non_terminals.include?(left)
          non_terminals[left] = non_terminals.length + 1
        end
      end

      @tokens = BiHash.new

      @tokens['$'] = 1
      productions.each do |_, right|
        right.each do |token|
          unless non_terminals.include?(token) ||
              @tokens.include?(token)

            @tokens[token] = @tokens.length + 1
          end
        end
      end

      @terminals_count = @tokens.length
      non_terminals.each do |token, index|
        @tokens[token] = @terminals_count + index
      end

      ####################
      # Initialize Items #
      ####################

      @items = []
      @initial_items = {}

      # At the same time we can fill in some data about productions
      @productions_for = Hash.new { |h, k| h[k] = Set.new }
      @production_tokens = {}

      productions.each_with_index do |(left, right), i|
        left_token = @tokens[left]
        @productions_for[left_token].add(i)
        @production_tokens[i] = left_token

        @initial_items[i] = @items.length
        right.each do |token|
          @items << @tokens[token]
        end
        @items << -i
      end

      ##################
      # Compute Tables #
      ##################

      @table_states = BiHash.new
      # The item set for state 0 is initialized to be the closure of
      # item 0, the start item.
      @table_states[closure(Set[0])] = 0

      # Initialize @next to a hash that initializes any missing keys
      # to a new nested hash when you attempt to access them.
      @next = Hash.new { |h, k| h[k] = {} }

      i = 0
      while i < @table_states.length
        table = @table_states.inverted[i]

        successors(table).each do |token, new_table|
          # Skip generating the table that would shift the eof token,
          # as we accept the input instead of visiting that state.
          if token == 0
            next
          end

          new_table = closure(new_table)

          # The only terribly smart thing we have to do in this whole
          # process is checking to see if the generated item set
          # already exists, and if so simply put in a @next entry
          # pointing to it.
          if @table_states.key?(new_table)
            @next[i][token] = @table_states[new_table]
          else
            id = @table_states.length
            @table_states[new_table] = id
            @next[i][token] = id
          end
        end

        i += 1
      end

      # Initialize @reduce to a hash that initializes any missing keys
      # to an empty set when you attempt to access them.
      @reduce = Hash.new { |h, k| h[k] = Set.new }

      @table_states.each do |table, i|
        table.each do |item|
          token = @items[item]
          # This is where putting the -production ids in the @items
          # array starts to pay off. We can find all of the items that
          # result in a reduction in a state just by looking for the
          # negative tokens
          if token < 0
            @reduce[i].add(-token)
          end
        end
      end
    end

    def states
      (0...@table_states.length).map do |i|
        {
          reduce: @reduce[i],
          next: @next[i].map do |token, state|
            [@tokens.inverted[token], state]
          end.to_h,
          items: @table_states.inverted[i].map do |item|
            item_string(item)
          end
        }
      end
    end

    def terminals
      @terminals ||= (1..@terminals_count).to_set
    end

    def non_terminals
      @non_terminals ||= ((@terminals_count + 1)...@tokens.length).to_set
    end

    end

    protected

    def successors(item_set)
      shifted_items = item_set.select do |item|
        # For each item that isn't the last item in its production.
        @items[item] > 0
      end.map { |item|
        # Generate a shifted item
        item + 1
      }

      shifted_items.group_by do |item|
        # Now we group the shifted items we generated based on the
        # id of the token that was shifted.
        @items[item - 1]

        # Then this converts the lists of grouped items into sets
      end.transform_values { |array| array.to_set() }
    end

    def closure(item_set)
      result = item_set.dup
      queue = item_set.to_a

      until queue.empty?
        i = queue.shift

        token = @items[i]

        # If the next token for the current item is a non-terminal
        if token > @terminals_count
          # Where @productions_for is assumed to map from token ids to
          # the set of production ids which have that token as their
          # left hand side.
          token_items = @productions_for[token].map do |production|
            @initial_items[production]
          end.to_set

          new_items = token_items - result

          queue += new_items.to_a
          result += new_items
        end
      end

      result
    end

    def item_string(current)
      production = item_production(current)
      output = "#{token_string(@production_tokens[production])} ->"
      production_items(production).each do |item|
        token = @items[item]
        if item == current
          output += " ."
        end
        output += " "
        output += token_string(token)
      end

      if @items[current] <= 0
        output += " ."
      end

      output
    end

    def item_production(i)
      while @items[i] > 0
        i += 1
      end

      -@items[i]
    end

    def token_string(i)
      token = @tokens.inverted[i]
      case token
      when Symbol
        token.to_s
      when String
        token.dump.gsub('"', "'")
      end
    end

    def production_items(production)
      first = @initial_items[production]
      last = @initial_items[production + 1] || @items.length
      first...(last - 1)
    end
  end
end
