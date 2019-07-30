# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Collection, type: :model do
  describe '#is_public' do
    it 'returns true if a collection is not restricted' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, restricted: false)

      expect(collection.is_public).to be true
    end

    it 'returns false if a collection is restricted' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, restricted: true)

      expect(collection.is_public).to be false
    end
  end
  context 'OCR Settings' do
    before :each do
      DatabaseCleaner.start
    end
    after :each do
      DatabaseCleaner.clean
    end
    
    let(:work_no_ocr) { create(:work) }
    let(:work_ocr)    { create(:work) }

    let(:collection) { build_stubbed(:collection, works: [work_no_ocr, work_ocr]) }
    describe '#enable_ocr' do
      it 'Enables OCR for all works' do
        collection.enable_ocr
        all_enabled = collection.works.all? {|w| w.ocr_correction }
        expect(all_enabled)
      end
    end
    describe '#disable_ocr' do
      it 'Disables OCR for all works' do
        collection.disable_ocr
        all_disabled = collection.works.none? {|w| w.ocr_correction }
        expect(all_disabled)
      end
    end
  end
end
