# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Collection, type: :model do
  describe 'validations' do
    context 'html validations' do
      let(:invalid_html) { '<p>Missing end tags' }
      let(:valid_html) { "<p>With \n special character &\n\n</p>" }
      let(:collection) { create(:collection) }

      it 'validates html syntax' do
        collection.intro_block = invalid_html
        expect(collection.valid?).to be_falsey

        collection.intro_block = valid_html
        expect(collection.valid?).to be_truthy
      end
    end
  end

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

  describe '#set_next_untranscribed_page' do
    let(:collection){ create(:collection, works: []) }
    let(:work){ create(:work, collection_id: collection.id) }
    it "sets nil with no works" do
      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(nil)
    end
    it "sets to untranscribed page in work" do
      page = create(:page, work_id: work.id)

      work.set_next_untranscribed_page
      expect(work.next_untranscribed_page).to eq(page)

      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(page)
    end
    it "sets to nil for no works with untranscribed pages" do
      create(:page, work_id: work.id, status: :transcribed)

      work.set_next_untranscribed_page
      expect(work.next_untranscribed_page).to eq(nil)

      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(nil)
    end
    it "sets to NUP of work with least complete" do
      create(:page, work_id: work.id, status: :transcribed)
      work_incomplete = create(:work, collection_id: collection.id)
      page_incomplete = create(:page, status: :new, work_id: work_incomplete.id)
      create(:page, status: :transcribed, work_id: work_incomplete.id)

      work.set_next_untranscribed_page
      work.save!
      work_incomplete.set_next_untranscribed_page
      work_incomplete.save!

      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(page_incomplete)
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

    let(:collection) { create(:collection, works: [work_no_ocr, work_ocr]) }
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

  describe '#enable_messageboards' do
    context 'when messageboard_group is nil' do
      let(:collection) { create(:collection, messageboard_group: nil) }

      it 'creates a messageboard group and default messageboards' do
        expect {
          collection.enable_messageboards
        }.to change(Thredded::MessageboardGroup, :count).by(1)
         .and change(Thredded::Messageboard, :count).by(2)

        expect(collection.messageboards_enabled).to be true
      end
    end
  end

end
