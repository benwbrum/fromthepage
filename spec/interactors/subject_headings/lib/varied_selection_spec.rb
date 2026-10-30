require 'spec_helper'

describe SubjectHeadings::Lib::VariedSelection do
  let(:militia) { ['militia company muster rifles drill captain', 'militia rifles muster company arms drill', 'captain militia drill company muster arms'] }
  let(:pardons) { ['pardon petition prisoner penitentiary sentence clemency', 'clemency pardon prisoner sentence petition jail', 'prisoner penitentiary pardon clemency sentence petition'] }
  let(:railroads) { ['railroad freight depot cars locomotive tracks', 'locomotive railroad tracks depot freight cars', 'freight cars railroad depot locomotive engine'] }
  let(:texts) { militia + pardons + railroads }

  it 'picks one typical document from each group of similar documents' do
    chosen = described_class.new(texts, count: 3, seed: 1).indexes.map { |i| texts[i] }

    expect(chosen.size).to eq(3)
    expect(chosen.count { |t| militia.include?(t) }).to eq(1)
    expect(chosen.count { |t| pardons.include?(t) }).to eq(1)
    expect(chosen.count { |t| railroads.include?(t) }).to eq(1)
  end

  it 'is deterministic for a given seed' do
    expect(described_class.new(texts, count: 4, seed: 7).indexes).to eq(described_class.new(texts, count: 4, seed: 7).indexes)
  end

  it 'returns the requested number of distinct indexes' do
    indexes = described_class.new(texts, count: 5, seed: 3).indexes
    expect(indexes.size).to eq(5)
    expect(indexes.uniq.size).to eq(5)
  end

  it 'returns every text when asked for more than there are' do
    expect(described_class.new(texts.first(2), count: 20).indexes).to contain_exactly(0, 1)
  end

  it 'returns nothing for no texts' do
    expect(described_class.new([], count: 20).indexes).to eq([])
  end
end
