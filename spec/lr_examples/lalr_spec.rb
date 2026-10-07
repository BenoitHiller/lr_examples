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
  let(:empty_transition_map) do
    parser.transitions.transform_values { Set[] }
  end

  context 'with Grammar 4' do
    let(:grammar) { Grammars::G4 }
    let(:expected_relation) do
      # This is unfortunately an extremely brittle test, but there is
      # little that can be done about that. Fetching the state ids by
      # some dynamic means would either add significant undesirable
      # constraints or compromise the test through introducing
      # circular dependency.
      {
        Edge[0, tokens[:B]] => Set[Edge[2, tokens[:C]]],
        Edge[2, tokens[:C]] => Set[Edge[5, tokens[:D]]],
        Edge[5, tokens[:D]] => Set[Edge[6, tokens[:B]]],
        Edge[6, tokens[:B]] => Set[Edge[2, tokens[:C]]]
      }
    end
    let(:expected_reads) do
      empty_transition_map.merge({
        Edge[0, tokens[:A]] => Set[tokens["$"]],
        Edge[0, tokens[:B]] => Set[tokens["a"]],
        Edge[2, tokens[:C]] => Set[tokens["a"]],
        Edge[5, tokens[:D]] => Set[tokens["a"]],
        Edge[6, tokens[:B]] => Set[tokens["a"]]
      })
    end

    it 'computes the reads relation' do
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
        Edge[2, tokens[:B]] => Set[
          Edge[0, tokens[:A]], Edge[8, tokens[:A]]
        ],
        Edge[8, tokens[:A]] => Set[Edge[6, tokens[:C]]],
        Edge[6, tokens[:C]] => Set[Edge[2, tokens[:B]]]
      }
    end
    let(:expected_follow) do
      {
        Edge[0, tokens[:A]] => Set[tokens["$"]],
        Edge[2, tokens[:B]] => Set[tokens["$"]],
        Edge[8, tokens[:A]] => Set[tokens["$"]],
        Edge[6, tokens[:C]] => Set[tokens["$"]]
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
        Edge[2, 3] => Set[tokens["$"]],
        Edge[3, 2] => Set[tokens["$"]],
        Edge[5, 1] => Set[tokens["$"]],
        Edge[7, 4] => Set[tokens["$"]],
        Edge[9, 5] => Set[tokens["$"]]
      }
    end

    let(:expected_reduce) do
      {
        2 => { tokens["$"] => Set[3] },
        3 => { tokens["$"] => Set[2] },
        5 => { tokens["$"] => Set[1] },
        7 => { tokens["$"] => Set[4] },
        9 => { tokens["$"] => Set[5] }
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

  context 'with Anderson Grammar' do
    let(:grammar) { Grammars::GAnderson }

    it 'prints' do
      table = parser.action_table
      rp table
    end
  end
end
