require 'spec_helper'

describe AiTranscription::BulkRetry do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection, pages: []) }
  let!(:page_1) { create(:page, :with_image, work: work) }
  let!(:page_2) { create(:page, :with_image, work: work) }

  let!(:ai_transcription_1) { create(:ai_transcription, page_id: page_1.id, status: :processing, source_text: nil, reasoning: nil) }
  let!(:ai_transcription_2) { create(:ai_transcription, page_id: page_2.id, status: :error, source_text: nil, reasoning: nil) }

  let(:user) { owner }

  let(:result) do
    described_class.new(
      collection: collection,
      user: user
    ).call
  end

  before do
    Current.user = user
  end

  it 'retries processing ai_transcription records' do
    expect(result.success?).to be_truthy
    expect(result.ai_transcription_ids).to contain_exactly(ai_transcription_2.id)
    expect(ai_transcription_2.reload.status_processing?).to be_truthy
  end
end
