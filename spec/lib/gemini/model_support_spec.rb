require 'spec_helper'

RSpec.describe 'Gemini model support' do
  describe AiTranscription::Lib::Gemini::TranscribeHandler do
    it 'supports gemini-3-flash-preview on v1beta' do
      expect(described_class::VERSION_MAP['gemini-3-flash-preview']).to eq('v1beta')
    end
  end

  describe Gemini::TextTranscriber do
    it 'supports gemini-3-flash-preview on v1beta' do
      expect(described_class::VERSION_MAP['gemini-3-flash-preview']).to eq('v1beta')
    end
  end
end
