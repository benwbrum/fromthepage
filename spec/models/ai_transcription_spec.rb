require 'spec_helper'

RSpec.describe AiTranscription, type: :model do
  let(:ai_transcription) { AiTranscription.new(model: AiTranscription::DEFAULT_MODEL) }

  describe '#replace_nbsp' do
    it 'replaces non-breaking spaces with regular spaces' do
      ai_transcription.source_text = 'Hello&nbsp;World'
      ai_transcription.replace_nbsp
      expect(ai_transcription.source_text).to eq('Hello World')
    end

    it 'does not change the source_text if it is nil' do
      ai_transcription.source_text = nil
      ai_transcription.replace_nbsp
      expect(ai_transcription.source_text).to be_nil
    end
  end
end