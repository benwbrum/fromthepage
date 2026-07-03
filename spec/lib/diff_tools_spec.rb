require 'spec_helper'
require 'diff_tools'

RSpec.describe DiffTools do
  describe '.diff_and_replace' do
    it 'returns identical text unchanged' do
      expect(Diffy::Diff).not_to receive(:new)

      expect(described_class.diff_and_replace('same text', 'same text', '[...]')).to eq('same text')
    end

    it 'replaces changed inline text with the replacement marker' do
      result = described_class.diff_and_replace('hello old world', 'hello new world', '[changed]')

      expect(result).to include('hello')
      expect(result).to include('[changed]')
      expect(result).to include('world')
      expect(result).not_to include('old')
      expect(result).not_to include('new')
    end

    it 'omits deleted lines from the replacement output' do
      result = described_class.diff_and_replace("keep\nremove", "keep", '[changed]')

      expect(result).to eq('keep')
    end
  end

  describe '.replace_words' do
    it 'replaces words containing the replacement marker with the marker' do
      expect(described_class.replace_words('before abcTOKENxyz after', 'TOKEN')).to eq('before TOKEN after')
    end
  end
end
