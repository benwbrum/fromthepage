require 'spec_helper'

describe AiTranscription::BulkRetryJob do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, :with_image, work: work) }

  let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, status: :processing, source_text: nil, reasoning: nil) }

  subject(:worker) { described_class }

  let(:perform_worker) do
    worker.perform_now(user_id: owner.id, ai_transcription_ids: [ai_transcription.id])
  end

  it 'enqueues GenerateJob for ai_transcriptions' do
    expect(AiTranscription::GenerateJob).to receive(:perform_later).with(
      ai_transcription_id: ai_transcription.id,
      user_id: owner.id
    )

    perform_worker
  end
end
