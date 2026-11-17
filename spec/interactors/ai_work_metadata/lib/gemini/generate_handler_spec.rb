require 'spec_helper'

describe AiWorkMetadata::Lib::Gemini::GenerateHandler do
  %w[
    gemini-3.1-pro-preview
    gemini-3-flash-preview
    gemini-3.5-flash
    gemini-3.6-flash
    gemini-3.7-flash
  ].each do |model|
    it "includes thought summaries in requests to #{model}" do
      handler = described_class.new(prompt: 'Describe this work', model: model)

      expect(handler.send(:payload)).to include(
        generation_config: { thinking_config: { include_thoughts: true } }
      )
    end
  end

  subject(:handler) { described_class.new(prompt: 'Describe this work', model: 'gemini-3.7-flash') }

  let(:response) do
    {
      'candidates' => [{ 'content' => { 'parts' => [
        { 'text' => 'Consider the title.', 'thought' => true },
        { 'text' => '{"1":"A Title"}' },
        { 'inlineData' => {} }
      ] } }],
      'usageMetadata' => {
        'promptTokenCount' => 10, 'candidatesTokenCount' => 5,
        'thoughtsTokenCount' => 2, 'totalTokenCount' => 17
      }
    }
  end
  let(:client) { double('Gemini client', generate_content: response) }

  before do
    allow(handler).to receive(:client).and_return(client)
  end

  it 'extracts metadata, reasoning, usage, and the raw response' do
    expect(handler.perform).to eq([
      '{"1":"A Title"}', 'Consider the title.',
      { prompt_token_count: 10, candidates_token_count: 5, thoughts_token_count: 2, total_token_count: 17 },
      response
    ])
  end

  it 'handles a response with no candidates or usage' do
    allow(client).to receive(:generate_content).and_return({})

    expect(handler.perform).to eq(['', '', {}, {}])
  end

  it 'retries a 503 response before succeeding' do
    calls = 0
    allow(client).to receive(:generate_content) do
      calls += 1
      raise StandardError, '503 overloaded' if calls == 1

      response
    end
    expect(handler).to receive(:sleep).with(2)

    expect(handler.perform.first).to eq('{"1":"A Title"}')
    expect(calls).to eq(2)
  end

  it 'stops retrying after the retry limit' do
    allow(client).to receive(:generate_content).and_raise(StandardError, '503 overloaded')
    allow(handler).to receive(:sleep)

    expect { handler.perform }.to raise_error(StandardError, '503 overloaded')
    expect(client).to have_received(:generate_content).exactly(described_class::MAX_RETRY + 1).times
    expect(handler).to have_received(:sleep).exactly(described_class::MAX_RETRY).times
  end

  it 'redacts credentials when logging a non-retryable error' do
    error = StandardError.new('403 https://provider.example/generate?key=fake-secret')
    allow(client).to receive(:generate_content).and_raise(error)
    expect(handler).not_to receive(:sleep)
    expect(Rails.logger).to receive(:error).with('Gemini API error: 403 https://provider.example/generate?key=[FILTERED]')

    expect { handler.perform }.to raise_error(error)
  end

  it 'requires a Gemini API key' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return(nil)

    expect { handler.send(:api_key) }.to raise_error(ArgumentError, /GEMINI_API_KEY/)
  end

  it 'constructs a Gemini client using the supplied model and API version' do
    allow(handler).to receive(:client).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return('fake-key')
    expect(::Gemini).to receive(:new).with(
      credentials: { service: 'generative-language-api', api_key: 'fake-key', version: 'v1beta' },
      options: { model: 'gemini-3.7-flash' }
    ).and_return(client)

    expect(handler.perform.first).to eq('{"1":"A Title"}')
  end
end
