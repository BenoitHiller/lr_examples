EXPECTED_STATES = [
  {
    reduce: Set[],
    items: [
      "S -> . E '$'",
      "E -> . E '+' B",
      "E -> . E '*' B",
      "E -> . B",
      "B -> . '0'",
      "B -> . '1'"
    ],
    next: {
      '0' => 3,
      '1' => 4,
      E: 1,
      B: 2
    }
  }, {
    reduce: Set[],
    items: [
      "S -> E . '$'",
      "E -> E . '+' B",
      "E -> E . '*' B"
    ],
    next: {
      '$' => 5,
      '+' => 6,
      '*' => 7
    }
  }, {
    reduce: Set[3],
    items: [
      "E -> B ."
    ],
    next: {}
  }, {
    reduce: Set[4],
    items: [
      "B -> '0' ."
    ],
    next: {}
  }, {
    reduce: Set[5],
    items: [
      "B -> '1' ."
    ],
    next: {}
  }, {
    reduce: Set[],
    items: [
      "S -> E '$' ."
    ],
    next: {}
  }, {
    reduce: Set[],
    items: [
      "E -> E '+' . B",
      "B -> . '0'",
      "B -> . '1'"
    ],
    next: {
      '0' => 3,
      '1' => 4,
      B: 8
    }
  }, {
    reduce: Set[],
    items: [
      "E -> E '*' . B",
      "B -> . '0'",
      "B -> . '1'"
    ],
    next: {
      '0' => 3,
      '1' => 4,
      B: 9
    }
  }, {
    reduce: Set[1],
    items: [
      "E -> E '+' B ."
    ],
    next: {}
  }, {
    reduce: Set[2],
    items: [
      "E -> E '*' B ."
    ],
    next: {}
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
