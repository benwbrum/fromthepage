require 'spec_helper'

describe Segmentation::Generate do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work, position: 2) }

  let(:metadata) do
    {
      prompt_token_count: 210,
      candidates_token_count: 3,
      thoughts_token_count: 40,
      total_token_count: 253
    }
  end

  before do
    allow(page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')
    allow(AiTranscription::Lib::Gemini::TranscribeHandler).to receive(:new).and_return(handler)
  end

  context 'when the page looks like a first page' do
    let(:handler) { instance_double(AiTranscription::Lib::Gemini::TranscribeHandler, perform: ['Yes.', '', metadata, {}]) }

    it 'flags the page as a first-page candidate' do
      described_class.new(page: page).perform

      expect(page.reload.is_first_page_candidate?).to be true
    end

    it 'logs the token usage for the call' do
      expect { described_class.new(page: page).perform }.to change(SegmentationLog, :count).by(1)

      log = SegmentationLog.last
      expect(log.page).to eq(page)
      expect(log.work_id).to eq(work.id)
      expect(log.model).to eq(described_class::MODEL)
      expect(log.is_first_page_candidate).to be true
      expect(log.status).to eq('finished')
      expect(log.total_token_count).to eq(253)
    end
  end

  context 'when the page does not look like a first page' do
    let(:handler) { instance_double(AiTranscription::Lib::Gemini::TranscribeHandler, perform: ['No.', '', metadata, {}]) }

    it 'does not flag the page' do
      described_class.new(page: page).perform

      expect(page.reload.is_first_page_candidate?).to be false
    end

    it 'still logs the call' do
      described_class.new(page: page).perform

      expect(SegmentationLog.last.is_first_page_candidate).to be false
    end
  end

  context 'when the page has no image' do
    let(:handler) { instance_double(AiTranscription::Lib::Gemini::TranscribeHandler) }

    before do
      allow(page).to receive(:image_url_for_download).and_return(nil)
    end

    it 'raises without logging or calling the model' do
      count_before = SegmentationLog.count

      expect { described_class.new(page: page).perform }.to raise_error(ArgumentError)

      expect(SegmentationLog.count).to eq(count_before)
    end
  end
end
