EXPECTED_STATES = [
  {
    reduce0: Set[],
    items: [
      "S -> . E '$'",
      "E -> . E '+' B",
      "E -> . E '*' B",
      "E -> . B",
      "B -> . '0'",
      "B -> . '1'"
    ],
    next0: {
      '0' => 3,
      '1' => 4,
      E: 1,
      B: 2
    }
  }, {
    reduce0: Set[],
    items: [
      "S -> E . '$'",
      "E -> E . '+' B",
      "E -> E . '*' B"
    ],
    next0: {
      '$' => 5,
      '+' => 6,
      '*' => 7
    }
  }, {
    reduce0: Set[3],
    items: [
      "E -> B ."
    ],
    next0: {}
  }, {
    reduce0: Set[4],
    items: [
      "B -> '0' ."
    ],
    next0: {}
  }, {
    reduce0: Set[5],
    items: [
      "B -> '1' ."
    ],
    next0: {}
  }, {
    reduce0: Set[],
    items: [
      "S -> E '$' ."
    ],
    next0: {}
  }, {
    reduce0: Set[],
    items: [
      "E -> E '+' . B",
      "B -> . '0'",
      "B -> . '1'"
    ],
    next0: {
      '0' => 3,
      '1' => 4,
      B: 8
    }
  }, {
    reduce0: Set[],
    items: [
      "E -> E '*' . B",
      "B -> . '0'",
      "B -> . '1'"
    ],
    next0: {
      '0' => 3,
      '1' => 4,
      B: 9
    }
  }, {
    reduce0: Set[1],
    items: [
      "E -> E '+' B ."
    ],
    next0: {}
  }, {
    reduce0: Set[2],
    items: [
      "E -> E '*' B ."
    ],
    next0: {}
  }
]

RSpec.describe LrExamples::Lr0 do
  subject(:parser) { described_class.new(grammar) }

  context 'with Grammar 3' do
    let(:grammar) { Grammars::G3 }

    it 'computes the parser states' do
      expect(parser.states).to eq(EXPECTED_STATES)
    end
  end

  context 'with Grammar 4' do
    let(:grammar) { Grammars::G4 }

    it 'computes the nullable tokens' do
      token_ids = parser.nullable_tokens

      tokens = token_ids.map do |id|
        parser.tokens.inverted[id]
      end.to_set

      expect(tokens).to eq(Set[:B, :C, :D])
    end
  end
end
