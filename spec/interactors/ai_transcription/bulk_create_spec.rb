require 'spec_helper'

describe AiTranscription::BulkCreate do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection, pages: []) }
  let!(:page_1) { create(:page, :with_image, work: work) }
  let!(:page_2) { create(:page, :with_image, work: work) }

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

  it 'initializes processing ai_transcription records' do
    expect(result.full_errors).to eq(nil)
    expect(result.success?).to be_truthy
    ai_transcriptions = collection.pages.includes(:ai_transcription).map(&:ai_transcription)
    expect(ai_transcriptions.size).to eq(2)
    expect(ai_transcriptions.pluck(:status).uniq).to eq(['processing'])
  end

  context 'when ai_transcription for page exist' do
    let!(:ai_transcription) { create(:ai_transcription, page_id: page_1.id, source_text: nil, status: :new) }

    it 'initializes processing ai_transcription records' do
      expect(result.success?).to be_truthy
      ai_transcriptions = collection.pages.includes(:ai_transcription).map(&:ai_transcription)
      expect(ai_transcriptions.size).to eq(2)
      expect(ai_transcriptions.pluck(:id)).to include(ai_transcription.id)
      expect(ai_transcriptions.pluck(:status).uniq).to eq(['processing'])
    end
  end
end
