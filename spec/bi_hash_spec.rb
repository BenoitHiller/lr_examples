RSpec.describe LrExamples::BiHash do
  subject(:data) { described_class.new }

  it 'can fetch keys by value' do
    data[1] = "1"
    expect(data.inverted["1"]).to be 1
  end

  it 'can update values' do
    data[1] = "1"
    data[1] = "2"
    expect(data.inverted["2"]).to be 1
    expect(data.inverted["1"]).to be_nil
    expect(data[1]).to eq "2"
  end

  it 'can be enumerated' do
    data[1] = "a"
    data[2] = "b"
    data[3] = "c"
    expect(data.to_a).to eq([[1, "a"], [2, "b"], [3, "c"]])
  end

  it 'can return its length' do
    expect(data.length).to be 0
    data[1] = "a"
    data[2] = "b"
    data[3] = "c"
    expect(data.length).to be 3
  end

  context 'when inverted' do
    subject(:inverted) { data.inverted }

    it 'can update values' do
      inverted[1] = "a"
      expect(inverted[1]).to eq "a"
      expect(data["a"]).to be 1
      inverted[1] = "b"
      expect(data["a"]).to be_nil
      expect(data["b"]).to be 1
    end

    it 'can be enumerated' do
      data[1] = "a"
      data[2] = "b"
      data[3] = "c"
      expect(inverted.to_a).to eq([["a", 1], ["b", 2], ["c", 3]])
    end
  end
end
