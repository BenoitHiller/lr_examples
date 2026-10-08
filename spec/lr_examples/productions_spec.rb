RSpec.describe LrExamples::Productions do
  it 'defines productions' do
    expect(Grammars::G1.productions).to eq([
      [:$accept, [:S, "$"]],
      [:S, [:A]],
      [:A, ["(", :A, ")", :A]],
      [:A, []]
    ])
  end
end
