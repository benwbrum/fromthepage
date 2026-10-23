require 'spec_helper'

describe AiWorkMetadata::Generate do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:text_field) do
    create(:transcription_field, :as_metadata, :text_field,
           label: 'Title', collection: collection, position: 1, line_number: 1)
  end

  let!(:ai_work_metadata) do
    create(:ai_work_metadata, work_id: work.id, model: model, prompt: 'Sample prompt', status: :processing,
                              metadata_json: nil, reasoning: nil)
  end

  let(:model) { AiWorkMetadata::DEFAULT_MODEL }
  let(:response_json) { { text_field.id.to_s => 'A great title' }.to_json }
  let(:handler_response) { [response_json, 'because reasons', { 'total_token_count' => 42 }, nil] }

  let(:result) { described_class.new(ai_work_metadata: ai_work_metadata).call }

  before do
    Current.user = owner
    allow_any_instance_of(AiWorkMetadata::Lib::Gemini::GenerateHandler).to receive(:perform).and_return(handler_response)
    allow_any_instance_of(AiWorkMetadata::Lib::Claude::GenerateHandler).to receive(:perform).and_return(handler_response)
    allow_any_instance_of(AiWorkMetadata::Lib::OpenAi::GenerateHandler).to receive(:perform).and_return(handler_response)
  end

  context 'when the response is valid JSON matching the expected fields' do
    it 'stores the parsed metadata_json, reasoning, and metadata' do
      expect(result.success?).to be_truthy
      ai_work_metadata.reload
      expect(ai_work_metadata.metadata_json).to eq({ text_field.id.to_s => 'A great title' })
      expect(ai_work_metadata.reasoning).to eq('because reasons')
      expect(ai_work_metadata.metadata).to eq({ 'total_token_count' => 42 })
    end
  end

  context 'when the model is a claude model' do
    let(:model) { 'claude-sonnet-4-6' }

    it 'uses the claude handler' do
      expect(result.success?).to be_truthy
      ai_work_metadata.reload
      expect(ai_work_metadata.metadata_json).to eq({ text_field.id.to_s => 'A great title' })
    end
  end

  context 'when the model is an openai model' do
    let(:model) { 'gpt-4o' }

    it 'uses the openai handler' do
      expect(result.success?).to be_truthy
      ai_work_metadata.reload
      expect(ai_work_metadata.metadata_json).to eq({ text_field.id.to_s => 'A great title' })
    end
  end

  context 'when the response is not valid JSON' do
    let(:response_json) { 'not json at all' }

    it 'fails and stores the reasoning/metadata but not metadata_json' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to include('AI work metadata JSON validation failed')

      ai_work_metadata.reload
      expect(ai_work_metadata.metadata_json).to be_nil
      expect(ai_work_metadata.reasoning).to eq('because reasons')
    end
  end

  context 'when the response is missing an expected field' do
    let(:response_json) { {}.to_json }

    it 'fails validation' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to include('Missing fields')
    end
  end
end
