module LrExamples
  class Lr0
    using CoreExtensions
    include Memoized

    attr_reader(
      :tokens,
      :items,
      :next0,
      :reduce0,
      :productions_for,
      :initial_items,
      :table_states
    )

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
      @productions_for = Hash.with_default(Set)
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

      build_table_states!
    end

    memoized def terminals
      (1..@terminals_count).to_set
    end

    memoized def non_terminals
      ((@terminals_count + 1)..@tokens.length).to_set
    end

    def nullable_tokens
      nullable = Set.new

      # The set of non_terminals on the right hand side of each
      # production. As the algorithm proceeds we will prune the
      # nullable tokens as we find them until it the set is empty at
      # which point we know the production is nullable.
      production_dependencies = Hash.new { |h, k| h[k] = Set.new }

      # This is the inverse mapping for the initial value of
      # production_dependencies
      has_token = Hash.new { |h, k| h[k] = Set.new }

      @production_tokens.each do |production, left|
        tokens = production_items(production).map do |item|
          @items[item]
        end.to_set

        if tokens.empty?
          nullable.add(left)
        else
          if (tokens & terminals).empty?
            production_dependencies[production] = tokens

            tokens.each do |token|
              has_token[token].add(production)
            end
          end
        end
      end

      queue = nullable.to_a

      # For each nullable token there must exist a parse tree with
      # that token at the root such that every node in the tree is
      # also a nullable token.
      #
      # The implication of that is that we can enumerate all such
      # tokens by iteratively computing all of the tokens that can
      # be generated with a tree of each depth. That is accomplished
      # here by processing them in FIFO order as we find them.
      until queue.empty?
        token = queue.shift()

        (has_token[token]).each do |production|
          left_token = @production_tokens[production]

          unless nullable.include?(left_token)
            production_dependencies[production].delete(token)

            if production_dependencies[production].empty?
              nullable.add(left_token)
              queue.push(left_token)
            end
          end
        end
      end

      nullable
    end
    # on a separate line to keep it out of the example source
    memoized :nullable_tokens

    def tokens_for(production)
      production_items(production).map(&@items)
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

                    next_state = @next0.dig(state, @items[current])

                    if !next_state.nil?
                      rp.write("shift")
                      rp.rp(@tokens.inverted[@items[current]])
                      rp.write("to")
                      rp.rp(next_state)
                    elsif !@reduce0[state].empty?
                      rp.write("reduce with")
                      rp.inline(", ") do
                        (@reduce0[state]).each do |reduction|
                          rp.rp(reduction)
                        end
                      end
                    else
                      rp.write("accept")
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

    protected

    def successors(item_set)
      shifted_items = item_set.select do |item|
        # For each item that isn't the last item in its production.
        @items[item] > 0
      end.map do |item|
        # Generate a shifted item
        item + 1
      end

      shifted_items.group_by do |item|
        # Now we group the shifted items we generated based on the
        # id of the token that was shifted.
        @items[item - 1]

        # Then this converts the lists of grouped items into sets
      end.transform_values do |array|
        array.to_set()
      end.sort_by do |token, _|
        token
      end
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

    private

    def build_table_states!
      # BiHash is a class I wrote that defines a bidirectional
      # hashmap, such that you can access it in the opposite direction
      # through the `inverted` method.
      #
      # This keeps the implementation a bit shorter, but you will
      # likely want to just maintain both maps in sync when doing this
      # yourself.
      #
      # There are many quirks to such a data-structure and there is
      # thus a good reason it isn't in the standard library for any
      # language.
      @table_states = BiHash.new

      # The item set for state 0 is initialized to be the closure of
      # item 0, the start item.
      @table_states[closure(Set[0])] = 0

      # Initialize @next0 to a hash that initializes any missing keys
      # to a new nested hash when you attempt to access them.
      @next0 = Hash.with_default(Hash)

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
          # already exists, and if so simply put in a @next0 entry
          # pointing to it.
          if @table_states.key?(new_table)
            @next0[i][token] = @table_states[new_table]
          else
            id = @table_states.length
            @table_states[new_table] = id
            @next0[i][token] = id
          end
        end

        i += 1
      end

      # Initialize @reduce0 to a hash that initializes any missing
      # keys to an empty set when you attempt to access them.
      @reduce0 = Hash.with_default(Set)

      @table_states.each do |table, i|
        table.each do |item|
          token = @items[item]
          # This is where putting the -production ids in the @items
          # array starts to pay off. We can find all of the items that
          # result in a reduction in a state just by looking for the
          # negative tokens
          if token < 0
            @reduce0[i].add(-token)
          end
        end
      end
    end
  end
end
