require 'forwardable'
require_relative 'digraph'

module LrExamples
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
          direct_reads[edge] =
            next0[next_state].keys.filter do |token|
              terminals.include?(token)
            end.to_set
        end
      end

      direct_reads
    end

    memoized def reads_relation
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

    memoized def reads
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
        productions_for[edge.label].each do |production|
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
  end
end
