require 'spec_helper'

RSpec.describe AiWorkMetadata, type: :model do
  let(:ai_work_metadata) { described_class.new(model: described_class::DEFAULT_MODEL) }

  describe '#engine' do
    it 'returns gemini for gemini models' do
      ai_work_metadata.model = 'gemini-3.7-flash'
      expect(ai_work_metadata.engine).to eq('gemini')
    end

    it 'returns claude for claude models' do
      ai_work_metadata.model = 'claude-sonnet-4-6'
      expect(ai_work_metadata.engine).to eq('claude')
    end

    it 'returns openai for openai models' do
      ai_work_metadata.model = 'gpt-4o'
      expect(ai_work_metadata.engine).to eq('openai')
    end
  end

  describe '.engine_for_model' do
    it 'returns gemini for unrecognized models' do
      expect(described_class.engine_for_model('some-unknown-model')).to eq('gemini')
    end

    it 'returns claude for claude-prefixed models' do
      expect(described_class.engine_for_model('claude-opus-4-6')).to eq('claude')
    end

    it 'returns openai for gpt-prefixed models' do
      expect(described_class.engine_for_model('gpt-4o')).to eq('openai')
    end

    it 'returns openai for o-series reasoning models' do
      expect(described_class.engine_for_model('o3-mini')).to eq('openai')
    end

    it 'returns openai for chatgpt-prefixed models' do
      expect(described_class.engine_for_model('chatgpt-4o-latest')).to eq('openai')
    end
  end

  describe '#error_message' do
    it 'returns nil when metadata is blank' do
      expect(ai_work_metadata.error_message).to be_nil
    end

    it 'redacts credentials from historical error metadata' do
      ai_work_metadata.metadata = {
        'error_message' => 'status 403: https://another-provider.example/path?access_token=fake-secret&key=another-secret'
      }

      expect(ai_work_metadata.error_message).to eq(
        'status 403: https://another-provider.example/path?access_token=[FILTERED]&key=[FILTERED]'
      )
      expect(ai_work_metadata.error_message).not_to include('fake-secret', 'another-secret')
    end
  end

  describe '#short_error_message' do
    it 'returns a default message when no error details are provided' do
      expect(ai_work_metadata.short_error_message).to eq('Error details not provided')
    end

    it 'truncates long error messages' do
      ai_work_metadata.metadata = { 'error_message' => 'a' * 300 }
      expect(ai_work_metadata.short_error_message.length).to eq(220)
    end
  end

  describe 'associations' do
    it 'is associated to work' do
      work = create(:work)
      ai_work_metadata = create(:ai_work_metadata, work_id: work.id)
      expect(ai_work_metadata.work).to eq(work)
      expect(ai_work_metadata.collection).to eq(work.collection)
    end
  end

  describe 'status enum' do
    it 'defaults to new' do
      expect(create(:ai_work_metadata)).to be_status_new
    end
  end
end
