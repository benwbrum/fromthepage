require 'spec_helper'

describe AiWorkMetadata::Lib::OpenAi::GenerateHandler do
  subject(:handler) do
    described_class.new(prompt: 'Extract metadata', model: 'gpt-4o')
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('OPENAI_ACCESS_TOKEN').and_return('fake-token')
  end

  it 'extracts the metadata text and usage from a successful response' do
    response = {
      'choices' => [
        { 'message' => { 'content' => '{"1":"A Title"}' } }
      ],
      'usage' => {
        'prompt_tokens' => 10,
        'completion_tokens' => 5,
        'total_tokens' => 15
      }
    }
    client = double
    allow(client).to receive(:chat).and_return(response)
    allow(handler).to receive(:client).and_return(client)

    metadata_text, reasoning_text, metadata, raw_response = handler.perform

    expect(metadata_text).to eq('{"1":"A Title"}')
    expect(reasoning_text).to eq('')
    expect(metadata).to eq(
      prompt_token_count: 10,
      candidates_token_count: 5,
      total_token_count: 15
    )
    expect(raw_response).to eq(response)
  end

  it 'redacts credentials from provider errors before logging' do
    error = StandardError.new(
      'the server responded with status 429 for URL https://provider.example/generate?token=fake-secret&alt=json'
    )
    client = double
    allow(client).to receive(:chat).and_raise(error)
    allow(handler).to receive(:client).and_return(client)
    logged_messages = []
    allow(Rails.logger).to receive(:error) { |message| logged_messages << message }

    expect { handler.perform }.to raise_error(error)

    expect(logged_messages).to all(include('status 429'))
    expect(logged_messages).to all(include('provider.example/generate?token=[FILTERED]&alt=json'))
    expect(logged_messages.join).not_to include('fake-secret')
  end

  it 'retries on a retryable server error status before succeeding' do
    response = {
      'choices' => [{ 'message' => { 'content' => '{}' } }],
      'usage' => {}
    }
    retryable_error = Faraday::ServerError.new('overloaded', { status: 503 })
    client = double
    call_count = 0
    allow(client).to receive(:chat) do
      call_count += 1
      raise retryable_error if call_count == 1

      response
    end
    allow(handler).to receive(:client).and_return(client)
    allow(handler).to receive(:sleep)

    metadata_text, = handler.perform

    expect(metadata_text).to eq('{}')
    expect(call_count).to eq(2)
  end

  it 'raises ArgumentError when OPENAI_ACCESS_TOKEN is not set' do
    allow(ENV).to receive(:[]).with('OPENAI_ACCESS_TOKEN').and_return(nil)

    expect { handler.send(:api_key) }.to raise_error(ArgumentError, /OPENAI_ACCESS_TOKEN/)
  end
end
