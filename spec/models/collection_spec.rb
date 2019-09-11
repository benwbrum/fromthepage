# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Collection, type: :model do
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
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
      create(:page, work_id: work.id, status: Page::STATUS_TRANSCRIBED)

      work.set_next_untranscribed_page
      expect(work.next_untranscribed_page).to eq(nil)

      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(nil)
    end
    it "sets to NUP of work with least complete" do
      create(:page, work_id: work.id, status: Page::STATUS_TRANSCRIBED)
      work_incomplete = create(:work, collection_id: collection.id)
      page_incomplete = create(:page, status: nil, work_id: work_incomplete.id)
      create(:page, status: Page::STATUS_TRANSCRIBED, work_id: work_incomplete.id)
      
      work.set_next_untranscribed_page
      work.save!
      work_incomplete.set_next_untranscribed_page
      work_incomplete.save!

      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(page_incomplete)
    end
  end
end
