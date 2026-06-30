require 'spec_helper'

RSpec.describe AiTranscription, type: :model do
  let(:ai_transcription) { AiTranscription.new(model: AiTranscription::DEFAULT_MODEL) }

  describe '#supports_reasoning?' do
    it 'returns true for non-ALTO models' do
      expect(ai_transcription.supports_reasoning?).to be true
    end

    it 'returns false for the ALTO model' do
      alto = AiTranscription.new(model: AiTranscription::ALTO_MODEL)
      expect(alto.supports_reasoning?).to be false
    end
  end

  describe '#supports_prompt?' do
    it 'returns true for non-ALTO models' do
      expect(ai_transcription.supports_prompt?).to be true
    end

    it 'returns false for the ALTO model' do
      alto = AiTranscription.new(model: AiTranscription::ALTO_MODEL)
      expect(alto.supports_prompt?).to be false
    end
  end

  describe '#normalize_source_text' do
    it 'replaces non-breaking spaces with regular spaces' do
      ai_transcription.source_text = 'Hello&nbsp;World'
      ai_transcription.normalize_source_text
      expect(ai_transcription.source_text).to eq('Hello World')
    end

    it 'strips plain html br tags' do
      ai_transcription.source_text = 'Hello<br>World<br>Again'
      ai_transcription.normalize_source_text
      expect(ai_transcription.source_text).to eq("Hello\nWorld\nAgain")
    end

    it 'strips self-closing html br tags' do
      ai_transcription.source_text = 'Hello<br/>World<BR />Again'
      ai_transcription.normalize_source_text
      expect(ai_transcription.source_text).to eq("Hello\nWorld\nAgain")
    end

    it 'normalizes mixed br tags and non-breaking spaces' do
      ai_transcription.source_text = 'Hello&nbsp;<br />World'
      ai_transcription.normalize_source_text
      expect(ai_transcription.source_text).to eq("Hello \nWorld")
    end

    it 'does not change the source_text if it is nil' do
      ai_transcription.source_text = nil
      ai_transcription.normalize_source_text
      expect(ai_transcription.source_text).to be_nil
    end

    it 'does not change already clean text' do
      ai_transcription.source_text = 'Hello World'
      ai_transcription.normalize_source_text
      expect(ai_transcription.source_text).to eq('Hello World')
    end
  end
end
