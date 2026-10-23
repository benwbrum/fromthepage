require 'spec_helper'

describe AiWorkMetadata::GenerateJob do
  include ActiveJob::TestHelper

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:text_field) do
    create(:transcription_field, :as_metadata, :text_field,
           label: 'Title', collection: collection, position: 1, line_number: 1)
  end

  let!(:ai_work_metadata) do
    create(:ai_work_metadata, work_id: work.id, model: AiWorkMetadata::DEFAULT_MODEL, prompt: 'Sample prompt',
                              status: :processing, metadata_json: nil, reasoning: nil)
  end

  subject(:worker) { described_class.new }

  let(:perform_worker) do
    worker.perform(user_id: owner.id, ai_work_metadata_id: ai_work_metadata.id)
  end

  context 'success' do
    let(:response_json) { { text_field.id.to_s => 'A great title' }.to_json }
    let(:success_result) do
      instance_double('Result', success?: true, ai_work_metadata: ai_work_metadata)
    end

    before do
      allow(AiWorkMetadata::Generate).to receive(:new).with(ai_work_metadata: ai_work_metadata).and_return(
        instance_double(AiWorkMetadata::Generate, call: success_result)
      )
    end

    it 'marks the record as finished' do
      perform_enqueued_jobs do
        perform_worker
      end

      expect(ai_work_metadata.reload.status).to eq('finished')
    end

    context 'when user is admin' do
      let!(:admin) { create(:unique_user, :admin) }
      let(:perform_worker) do
        worker.perform(user_id: admin.id, ai_work_metadata_id: ai_work_metadata.id)
      end

      it 'marks the record as finished' do
        perform_enqueued_jobs do
          perform_worker
        end

        expect(ai_work_metadata.reload.status).to eq('finished')
      end
    end
  end

  context 'failure' do
    let(:error) { StandardError.new('some generation error') }
    let(:failure_result) do
      instance_double('Result', success?: false, ai_work_metadata: ai_work_metadata, full_errors: error)
    end

    before do
      allow(AiWorkMetadata::Generate).to receive(:new).with(ai_work_metadata: ai_work_metadata).and_return(
        instance_double(AiWorkMetadata::Generate, call: failure_result)
      )
    end

    it 'stores the error message and status' do
      expect {
        perform_enqueued_jobs do
          perform_worker
        end
      }.to raise_error

      ai_work_metadata.reload
      expect(ai_work_metadata.status).to eq('error')
      expect(ai_work_metadata.error_message).to eq('some generation error')
    end
  end

  context 'no permission' do
    let!(:user) { create(:unique_user) }

    let(:perform_worker) do
      worker.perform(user_id: user.id, ai_work_metadata_id: ai_work_metadata.id)
    end

    it 'raises and stores an error' do
      expect {
        perform_enqueued_jobs do
          perform_worker
        end
      }.to raise_error

      ai_work_metadata.reload
      expect(ai_work_metadata.status).to eq('error')
      expect(ai_work_metadata.error_message).to eq('User has no permission to create AiWorkMetadata on this work')
    end
  end
end
