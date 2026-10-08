Edge = LrExamples::Lalr::Edge

module TSV
  refine Enumerable do
    def to_tsv
      output = ""
      each do |row|
        output += row.map(&:to_s).join("\t") + "\n"
      end
      output
    end
  end
end
using TSV

RSpec.describe LrExamples::Lalr do
  subject(:parser) { described_class.new(grammar) }

  let(:tokens) { parser.tokens }
  let(:states) { parser.item_state_map }
  let(:empty_transition_map) do
    parser.transitions.transform_values { Set[] }
  end

  def edge(state, token)
    case state
    in Integer => production, Integer => index
      Edge[state(production, index), tokens[token]]
    else
      Edge[state, tokens[token]]
    end
  end

  def state(production, index)
    states[production][index].first
  end

  context 'with Grammar 4' do
    let(:grammar) { Grammars::G4 }
    # We identify states by asking "which state contains the nth
    # item of production 2".
    #
    # This relies on this particular grammar only having a single
    # entry for each such case, which is true here except for in the
    # case of state 0.
    let(:p2) { states[2].transform_values(&:first) }
    let(:expected_relation) do
      {
        edge(0, :F) => Set[edge(p2[1], :C)],
        edge(p2[1], :C) => Set[edge(p2[2], :D)],
        edge(p2[2], :D) => Set[edge(p2[3], :F)],
        edge(p2[3], :F) => Set[edge(p2[1], :C)]
      }
    end

    let(:expected_reads) do
      empty_transition_map.merge({
        edge(0, :S) => Set[tokens["$"]],
        edge(0, :F) => Set[tokens["a"]],
        edge(p2[1], :C) => Set[tokens["a"]],
        edge(p2[2], :D) => Set[tokens["a"]],
        edge(p2[3], :F) => Set[tokens["a"]]
      })
    end

    it 'computes the reads relation' do
      parser.reads
      expect(parser.reads_relation).to match(expected_relation)
    end

    it 'computes reads' do
      expect(parser.reads).to eq(expected_reads)
    end
  end

  context 'with Grammar 5' do
    let(:grammar) { Grammars::G5 }
    let(:expected_relation) do
      {
        edge([1, 0], :E) => Set[edge([0, 0], :S)],
        edge([2, 1], :F) => Set[
          edge([1, 0], :E), edge([5, 1], :E)
        ],
        edge([5, 1], :E) => Set[edge([4, 1], :G)],
        edge([4, 1], :G) => Set[edge([2, 1], :F)]
      }
    end
    let(:expected_follow) do
      {
        edge([0, 0], :S) => Set[tokens["$"]],
        edge([1, 0], :E) => Set[tokens["$"]],
        edge([2, 1], :F) => Set[tokens["$"]],
        edge([5, 1], :E) => Set[tokens["$"]],
        edge([4, 1], :G) => Set[tokens["$"]]
      }
    end

    it 'computes the includes relation' do
      expect(parser.includes_relation).to eq(expected_relation)
    end

    it 'computes follow' do
      expect(parser.follow).to eq(expected_follow)
    end
  end

  context 'with Grammar 5B' do
    let(:grammar) { Grammars::G5B }
    let(:expected_reads) do
      empty_transition_map.merge({
        Edge[0, 7] => Set[tokens["$"]]
      })
    end

    let(:expected_lookahead) do
      {
        Edge[state(1, 1), 1] => Set[tokens["$"]],
        Edge[state(2, 2), 2] => Set[tokens["$"]],
        Edge[state(3, 1), 3] => Set[tokens["$"]],
        Edge[state(4, 2), 4] => Set[tokens["$"]],
        Edge[state(5, 2), 5] => Set[tokens["$"]],
        Edge[state(6, 2), 6] => Set[tokens["$"]]
      }
    end

    let(:expected_reduce) do
      {
        state(1, 1) => { tokens["$"] => Set[1] },
        state(2, 2) => { tokens["$"] => Set[2] },
        state(3, 1) => { tokens["$"] => Set[3] },
        state(4, 2) => { tokens["$"] => Set[4] },
        state(5, 2) => { tokens["$"] => Set[5] },
        state(6, 2) => { tokens["$"] => Set[6] }
      }
    end

    it 'computes reads' do
      expect(parser.reads).to eq(expected_reads)
    end

    it 'computes the lookahead sets' do
      expect(parser.lookahead).to eq(expected_lookahead)
    end

    it 'computes reduce' do
      expect(parser.reduce).to eq(expected_reduce)
    end
  end

  context 'with Grammar 6' do
    let(:grammar) { Grammars::G6 }

    it 'prints' do
      table = parser.action_table
    end
  end
end
