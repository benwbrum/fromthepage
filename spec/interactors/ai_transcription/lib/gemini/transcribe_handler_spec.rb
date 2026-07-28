require 'spec_helper'

describe AiTranscription::Lib::Gemini::TranscribeHandler do
  subject(:handler) do
    described_class.new(prompt: 'Transcribe', model: 'gemini-test', image_url: 'https://example.com/image.jpg')
  end

  it 'redacts credentials from provider errors before logging' do
    error = StandardError.new(
      'the server responded with status 429 for URL https://provider.example/generate?token=fake-secret&alt=json'
    )
    allow(handler).to receive(:client).and_return(double(generate_content: nil))
    allow(handler.client).to receive(:generate_content).and_raise(error)
    logged_messages = []
    allow(Rails.logger).to receive(:error) { |message| logged_messages << message }

    expect { handler.perform }.to raise_error(error)

    expect(logged_messages).to all(include('status 429'))
    expect(logged_messages).to all(include('provider.example/generate?token=[FILTERED]&alt=json'))
    expect(logged_messages.join).not_to include('fake-secret')
  end
end
