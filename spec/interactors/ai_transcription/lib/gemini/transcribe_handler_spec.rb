require 'spec_helper'

describe AiTranscription::Lib::Gemini::TranscribeHandler do
  subject(:handler) do
    described_class.new(prompt: 'Transcribe', model: 'gemini-test', image_url: 'https://example.com/image.jpg')
  end

  it 'redacts credentials from provider errors before logging' do
    error = StandardError.new(
      'the server responded with status 429 for URL https://provider.example/generate?token=fake-secret&alt=json'
    )
    client = double
    allow(client).to receive(:generate_content).and_raise(error)
    allow(handler).to receive(:client).and_return(client)
    allow(handler).to receive(:payload).and_return({})
    logged_messages = []
    allow(Rails.logger).to receive(:error) { |message| logged_messages << message }

    expect { handler.perform }.to raise_error(error)

    expect(logged_messages).to all(include('status 429'))
    expect(logged_messages).to all(include('provider.example/generate?token=[FILTERED]&alt=json'))
    expect(logged_messages.join).not_to include('fake-secret')
  end

  describe 'usage metadata' do
    let(:usage_metadata) do
      {
        'promptTokenCount' => 100,
        'candidatesTokenCount' => 30,
        'thoughtsTokenCount' => 20,
        'toolUsePromptTokenCount' => 10,
        'cachedContentTokenCount' => 40,
        'totalTokenCount' => 165,
        'promptTokensDetails' => [{ 'modality' => 'TEXT', 'tokenCount' => 60 }],
        'candidatesTokensDetails' => [{ 'modality' => 'TEXT', 'tokenCount' => 30 }],
        'cacheTokensDetails' => [{ 'modality' => 'IMAGE', 'tokenCount' => 40 }],
        'toolUsePromptTokensDetails' => [{ 'modality' => 'TEXT', 'tokenCount' => 10 }],
        'futureProviderField' => { 'nested' => ['unchanged'] }
      }
    end

    let(:response) do
      {
        'candidates' => [{
          'content' => {
            'parts' => [
              { 'thought' => true, 'text' => 'Reasoning' },
              { 'text' => 'Transcription' }
            ]
          }
        }],
        'usageMetadata' => usage_metadata
      }
    end

    it 'preserves provider metadata and reconciles mutually exclusive token categories' do
      client = double(generate_content: response)
      allow(handler).to receive(:client).and_return(client)
      allow(handler).to receive(:payload).and_return({})

      transcription, reasoning, metadata, = handler.perform

      expect(transcription).to eq('Transcription')
      expect(reasoning).to eq('Reasoning')
      expect(metadata).to include(
        prompt_token_count: 100,
        candidates_token_count: 30,
        thoughts_token_count: 20,
        tool_use_prompt_token_count: 10,
        cached_content_token_count: 40,
        total_token_count: 165,
        accounted_token_count: 160,
        unaccounted_token_count: 5,
        usage_metadata_schema_version: 2,
        usage_metadata_reconciliation_status: 'unaccounted_tokens'
      )
      expect(metadata).to include(
        prompt_tokens_details: usage_metadata['promptTokensDetails'],
        candidates_tokens_details: usage_metadata['candidatesTokensDetails'],
        cache_tokens_details: usage_metadata['cacheTokensDetails'],
        tool_use_prompt_tokens_details: usage_metadata['toolUsePromptTokensDetails']
      )
      expect(metadata[:provider_usage_metadata]).to eq(usage_metadata)
    end
  end
end
