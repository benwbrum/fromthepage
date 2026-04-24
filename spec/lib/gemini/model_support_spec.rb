require 'spec_helper'

RSpec.describe 'Gemini model support' do
  describe AiTranscription::Lib::Gemini::TranscribeHandler do
    it 'uses v1beta for gemini-3-flash-preview' do
      handler = described_class.new(
        prompt: 'Test prompt',
        model: 'gemini-3-flash-preview',
        image_url: 'http://example.com/image.jpg'
      )

      allow(handler).to receive(:api_key).and_return('fake-key')
      allow(::Gemini).to receive(:new).and_return(double('gemini-client'))

      handler.send(:client)

      expect(::Gemini).to have_received(:new).with(
        hash_including(
          credentials: hash_including(version: 'v1beta'),
          options: hash_including(model: 'gemini-3-flash-preview')
        )
      )
    end
  end

  describe Gemini::TextTranscriber do
    it 'uses v1beta for gemini-3-flash-preview' do
      allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return('fake-key')
      allow(described_class).to receive(:fetch_and_encode_image).and_return('fake-image-data')
      allow(described_class).to receive(:default_prompt).and_return('prompt')

      client = double('gemini-client', stream_generate_content: [])
      allow(::Gemini).to receive(:new).and_return(client)

      described_class.transcribe_image('http://example.com/image.jpg', model: 'gemini-3-flash-preview')

      expect(::Gemini).to have_received(:new).with(
        hash_including(
          credentials: hash_including(version: 'v1beta'),
          options: hash_including(model: 'gemini-3-flash-preview')
        )
      )
    end
  end
end
