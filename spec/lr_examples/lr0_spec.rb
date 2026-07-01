RSpec.describe LrExamples::Lr0 do
  subject(:parser) { described_class.new(Grammar::G4) }

  it 'defines productions', skip: "TODO" do
    expect(parser.tokens).to be_nil
  end
end
