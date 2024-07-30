# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DocumentSet, type: :model do
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
  end
  describe '#set_next_untranscribed_page' do
    let(:collection){ create(:collection, works:[]) }
    let(:work){ create(:work, collection_id: collection.id) }
    it "sets nil with no works" do
      docset = create(:document_set)
      docset.set_next_untranscribed_page
      expect(docset.next_untranscribed_page).to eq(nil)
    end
    it "sets to untranscribed page in work" do
      page = create(:page, work_id: work.id)
      docset = create(:document_set, works:[work] )

      work.set_next_untranscribed_page
      expect(work.next_untranscribed_page).to eq(page)

      docset.set_next_untranscribed_page
      expect(docset.next_untranscribed_page).to eq(page)
    end
    it "sets to nil for no works with untranscribed pages" do
      create(:page, work_id: work.id, status: :transcribed)
      docset = create(:document_set, works:[work] )

      work.set_next_untranscribed_page
      expect(work.next_untranscribed_page).to eq(nil)

      docset.set_next_untranscribed_page
      expect(docset.next_untranscribed_page).to eq(nil)
    end
    it "sets to NUP of work with least complete" do
      create(:page, work_id: work.id, status: :transcribed)
      work_incomplete = create(:work, collection_id: collection.id)
      page_incomplete = create(:page, status: :new, work_id: work_incomplete.id)
      create(:page, status: :transcribed, work_id: work_incomplete.id)

      docset = create(:document_set, works:[work, work_incomplete] )

      work.save!
      work_incomplete.save!

      docset.set_next_untranscribed_page
      expect(docset.next_untranscribed_page).to eq(page_incomplete)
    end
  end
end
