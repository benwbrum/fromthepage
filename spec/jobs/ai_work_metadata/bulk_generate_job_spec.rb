require 'spec_helper'

describe AiWorkMetadata::BulkGenerateJob do
  include ActiveJob::TestHelper

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work_1) { create(:work, collection: collection) }
  let!(:work_2) { create(:work, collection: collection) }

  let!(:ai_work_metadata_1) { create(:ai_work_metadata, work_id: work_1.id, status: :processing, metadata_json: nil, reasoning: nil) }
  let!(:ai_work_metadata_2) { create(:ai_work_metadata, work_id: work_2.id, status: :processing, metadata_json: nil, reasoning: nil) }

  let(:scope) { nil }

  subject(:worker) { described_class }

  let(:perform_worker) do
    worker.perform_now(user_id: owner.id, collection_id: collection.id, scope: scope)
  end

  it 'enqueues GenerateJob for each processing ai_work_metadata record' do
    expect(AiWorkMetadata::GenerateJob).to receive(:perform_later).with(
      ai_work_metadata_id: ai_work_metadata_1.id,
      user_id: owner.id
    )
    expect(AiWorkMetadata::GenerateJob).to receive(:perform_later).with(
      ai_work_metadata_id: ai_work_metadata_2.id,
      user_id: owner.id
    )

    perform_worker
  end

  context 'when a record is finished' do
    let!(:ai_work_metadata_2) { create(:ai_work_metadata, work_id: work_2.id, status: :finished, metadata_json: nil, reasoning: nil) }

    it 'does not re-enqueue it' do
      expect(AiWorkMetadata::GenerateJob).to receive(:perform_later).with(
        ai_work_metadata_id: ai_work_metadata_1.id,
        user_id: owner.id
      )
      expect(AiWorkMetadata::GenerateJob).not_to receive(:perform_later).with(
        ai_work_metadata_id: ai_work_metadata_2.id,
        user_id: owner.id
      )

      perform_worker
    end
  end

  context 'when scoped to a work' do
    let!(:work_3) { create(:work, collection: collection) }
    let!(:ai_work_metadata_3) { create(:ai_work_metadata, work_id: work_3.id, status: :processing, metadata_json: nil, reasoning: nil) }

    let(:scope) { { work_ids: [work_1.id] } }

    it 'only enqueues GenerateJob for the scoped work' do
      expect(AiWorkMetadata::GenerateJob).to receive(:perform_later).with(
        ai_work_metadata_id: ai_work_metadata_1.id,
        user_id: owner.id
      )
      expect(AiWorkMetadata::GenerateJob).not_to receive(:perform_later).with(
        ai_work_metadata_id: ai_work_metadata_2.id,
        user_id: owner.id
      )
      expect(AiWorkMetadata::GenerateJob).not_to receive(:perform_later).with(
        ai_work_metadata_id: ai_work_metadata_3.id,
        user_id: owner.id
      )

      perform_worker
    end
  end
end
