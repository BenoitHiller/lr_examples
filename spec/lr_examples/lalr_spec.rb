using LrExamples::CoreExtensions

RSpec.describe LrExamples::Lalr do

  subject(:parser) { described_class.new(grammar) }

  before do
    stub_const('Edge', LrExamples::Edge)

    # Load the token ids for each non_terminal into their associated
    # constants to make the tests just a touch cleaner.
    grammar.constants.each do |name|
      value = grammar.const_get(name)
      if value.is_a?(LrExamples::Productions::Token)
        stub_const(name.to_s, tokens[name])
      end
    end
  end

  ##
  # Helper to fetch states based on the stable definition of an item
  def state(production, index)
    states[production][index].first
  end

  ##
  # Helper to generate edge objects more easily
  #
  # When the first argument is a pair [production, index], it makes
  # use of the #state helper to fetch the state number.
  def edge(state, token)
    case state
    in Integer => production, Integer => index
      Edge[state(production, index), token]
    else
      Edge[state, token]
    end
  end

  let(:tokens) { parser.tokens }

  # We identify states by asking "which state contains the nth
  # item of a given  production".
  #
  # This relies on the particular grammar only having a single entry
  # for each such case, which is thankfully true for most of the cases
  # we consider here.
  let(:states) do
    items_to_states = Hash.with_default(Set)
    parser.table_states.each do |items, state|
      items.each do |item|
        items_to_states[item].add(state)
      end
    end

    mapping = Hash.with_default(Hash)

    i = 0
    production = 0

    parser.items.each_with_index do |item, item_index|
      mapping[production][i] = items_to_states[item_index]

      if item > 0
        i += 1
      else
        i = 0
        production += 1
      end
    end

    mapping
  end

  let(:empty_transition_map) do
    parser.transitions.transform_values { Set[] }
  end

  context 'with Grammar 4' do
    let(:grammar) { Grammars::G4 }
    let(:expected_relation) do
      {
        edge(0, F) => Set[edge([2, 1], C)],
        edge([2, 1], C) => Set[edge([2, 2], D)],
        edge([2, 2], D) => Set[edge([2, 3], F)],
        edge([2, 3], F) => Set[edge([2, 1], C)]
      }
    end

    let(:expected_read) do
      empty_transition_map.merge({
        edge(0, S) => Set[tokens["$"]],
        edge(0, F) => Set[tokens["a"]],
        edge([2, 1], C) => Set[tokens["a"]],
        edge([2, 2], D) => Set[tokens["a"]],
        edge([2, 3], F) => Set[tokens["a"]]
      })
    end

    it 'computes the reads relation' do
      expect(parser.reads_relation).to match(expected_relation)
    end

    it 'computes read' do
      expect(parser.read).to eq(expected_read)
    end

    it "doesn't modify the reads relation when computing reads" do
      parser.read
      expect(parser.reads_relation).to match(expected_relation)
    end
  end

  context 'with Grammar 5' do
    let(:grammar) { Grammars::G5 }
    let(:expected_relation) do
      {
        edge([1, 0], E) => Set[edge([0, 0], S)],
        edge([2, 1], F) => Set[
          edge([1, 0], E), edge([5, 1], E)
        ],
        edge([5, 1], E) => Set[edge([4, 1], G)],
        edge([4, 1], G) => Set[edge([2, 1], F)]
      }
    end
    let(:expected_follow) do
      {
        edge([0, 0], S) => Set[tokens["$"]],
        edge([1, 0], E) => Set[tokens["$"]],
        edge([2, 1], F) => Set[tokens["$"]],
        edge([5, 1], E) => Set[tokens["$"]],
        edge([4, 1], G) => Set[tokens["$"]]
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
    let(:expected_read) do
      empty_transition_map.merge({
        Edge[0, 7] => Set[tokens["$"]]
      })
    end

    let(:expected_lookahead) do
      {
        Edge[state(1, 1), 1] => Set[tokens["$"]],
        Edge[state(2, 2), 2] => Set[tokens["$"]],
        Edge[state(3, 1), 3] => Set[tokens["$"]],
        Edge[state(4, 1), 4] => Set[tokens["$"]],
        Edge[state(5, 2), 5] => Set[tokens["$"]],
        Edge[state(6, 2), 6] => Set[tokens["$"]]
      }
    end

    let(:expected_reduce) do
      {
        state(1, 1) => { tokens["$"] => Set[1] },
        state(2, 2) => { tokens["$"] => Set[2] },
        state(3, 1) => { tokens["$"] => Set[3] },
        state(4, 1) => { tokens["$"] => Set[4] },
        state(5, 2) => { tokens["$"] => Set[5] },
        state(6, 2) => { tokens["$"] => Set[6] }
      }
    end

    it 'computes reads' do
      expect(parser.read).to eq(expected_read)
    end

    it 'computes the lookahead sets' do
      expect(parser.lookahead).to eq(expected_lookahead)
    end

    it 'computes reduce' do
      expect(parser.reduce).to eq(expected_reduce)
    end
  end
end
