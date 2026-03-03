require 'spec_helper'

describe AiTranscription::Lib::Gemini::TranscribeHandler do
  let(:handler) do
    described_class.new(
      prompt: 'Transcribe this image',
      model: AiTranscription::DEFAULT_MODEL,
      image_url: 'http://example.com/image.jpg'
    )
  end

  describe '#sanitize_text' do
    it 'replaces non-breaking spaces with regular spaces' do
      text_with_nbsp = "\u00A0\u00A0\u00A0Officer of the Day tomorrow"
      result = handler.send(:sanitize_text, text_with_nbsp)
      expect(result).to eq('   Officer of the Day tomorrow')
      expect(result).not_to include("\u00A0")
    end

    it 'leaves regular spaces unchanged' do
      text = "Officer of the Day tomorrow\nCapt Thomas"
      expect(handler.send(:sanitize_text, text)).to eq(text)
    end

    it 'replaces multiple non-breaking spaces throughout the text' do
      text = "First\u00A0line\u00A0\u00A0Second\u00A0line"
      result = handler.send(:sanitize_text, text)
      expect(result).to eq('First line  Second line')
      expect(result).not_to include("\u00A0")
    end
  end

  describe '#extract_texts_from_response' do
    it 'replaces non-breaking spaces in transcription text' do
      response = {
        'candidates' => [
          {
            'content' => {
              'parts' => [
                { 'text' => "\u00A0\u00A0\u00A0Officer of the Day tomorrow\nCapt Thomas" }
              ]
            }
          }
        ]
      }

      transcription_text, reasoning_text = handler.send(:extract_texts_from_response, response)

      expect(transcription_text).to eq("   Officer of the Day tomorrow\nCapt Thomas")
      expect(transcription_text).not_to include("\u00A0")
      expect(reasoning_text).to eq('')
    end
  end
end
