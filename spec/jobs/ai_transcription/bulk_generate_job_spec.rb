require 'spec_helper'

describe AiTranscription::BulkGenerateJob do
  include ActiveJob::TestHelper

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page_1) { create(:page, :with_image, work: work) }
  let!(:page_2) { create(:page, :with_image, work: work) }

  let!(:ai_transcription_1) { create(:ai_transcription, page_id: page_1.id, status: :processing, source_text: nil, reasoning: nil) }
  let!(:ai_transcription_2) { create(:ai_transcription, page_id: page_2.id, status: :processing, source_text: nil, reasoning: nil) }

  subject(:worker) { described_class }

  let(:perform_worker) do
    worker.perform_now(user_id: owner.id, collection_id: collection.id)
  end

  it 'enqueues GenerateJob for ai_transcriptions' do
    expect(AiTranscription::GenerateJob).to receive(:perform_later).with(
      ai_transcription_id: ai_transcription_1.id,
      user_id: owner.id
    )
    expect(AiTranscription::GenerateJob).to receive(:perform_later).with(
      ai_transcription_id: ai_transcription_2.id,
      user_id: owner.id
    )

    perform_worker
  end
end
