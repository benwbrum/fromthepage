# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Work, type: :model do
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
  end
  describe '#supports_indexing?' do
    it "returns true if a work's collection does not have subjects disabled" do
      collection = create(:collection, :with_pages, subjects_disabled: false)
      work = collection.works.first

      expect(work.supports_indexing?).to be true
    end

    it "returns false if a work's collection has subjects disabled" do
      collection = create(:collection, :with_pages, subjects_disabled: true)
      work = collection.works.first

      expect(work.supports_indexing?).to be false
    end
  end
  describe '#set/update_next_untranscribed_page' do
    let(:work) { create(:work, owner_user_id: 1) }
    it "sets nil with no pages" do
      work.set_next_untranscribed_page
      expect(work.next_untranscribed_page).to eq(nil)
    end
    it "sets untranscribed page to lowest positioned untrancribed page" do
      page_ten = create(:page, work_id: work.id, status: :new, position: 10)
      create(:page, work_id: work.id, status: :transcribed, position: 5)
      work.set_next_untranscribed_page

      expect(work.next_untranscribed_page).to eq(page_ten)

      page_one = create(:page, work_id: work.id, status: :new, position: 1)
      work.set_next_untranscribed_page

      expect(work.next_untranscribed_page).to eq(page_one)
    end

    it "sets nil with no untranscribed pages" do
      create(:page, work_id: work.id, status: :transcribed)
      work.set_next_untranscribed_page

      expect(work.next_untranscribed_page).to eq(nil)
    end
  end
end
