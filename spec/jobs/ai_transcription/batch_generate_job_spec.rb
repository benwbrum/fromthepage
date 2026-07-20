require 'spec_helper'

describe AiTranscription::BatchGenerateJob do
  include ActiveJob::TestHelper

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page_1) { create(:page, :with_image, work: work, cached_ai_status: :processing) }
  let!(:page_2) { create(:page, :with_image, work: work, cached_ai_status: :processing) }

  let(:scope) { nil }

  subject(:worker) { described_class }

  let(:perform_worker) do
    worker.perform_now(user_id: owner.id, collection_id: collection.id, scope: scope)
  end

  before do
    allow_any_instance_of(Page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')
  end

  it 'calls batch api and enqueues poll job' do
    expect {
      VCR.use_cassette('ai_transcriptions/batch_generate', record: :none) do
        perform_worker
      end
    }.to have_enqueued_job(AiTranscription::BatchPollJob).with(
        user_id: owner.id,
        ai_batch_generation_id: kind_of(Integer)
      )

    ai_batch_generation = collection.reload.ai_batch_generations.first
    expect(ai_batch_generation.batch_key).to eq('batches/redacted')
    expect(ai_batch_generation.pages.count).to eq(2)
    expect(ai_batch_generation.ai_transcriptions.count).to eq(2)
  end
end
