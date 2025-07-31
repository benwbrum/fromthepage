require 'spec_helper'

describe Work do
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

  context 'es_search' do
    let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

    let!(:owner) { create(:unique_user, :owner) }
    let!(:collection) { create(:collection, owner_user_id: owner.id) }
    let!(:restricted_collection) { create(:collection, owner_user_id: owner.id, restricted: true) }
    let!(:docset) { create(:document_set, collection_id: restricted_collection.id, owner_user_id: owner.id, visibility: :public) }
    let!(:restricted_docset) { create(:document_set, collection_id: restricted_collection.id, owner_user_id: owner.id, visibility: :private) }

    let!(:public_work) { create(:work, title: identifier, collection_id: collection.id, owner_user_id: owner.id) }
    let!(:restricted_work) { create(:work, collection_id: restricted_collection.id, owner_user_id: owner.id) }

    let!(:restricted_col_public_set_work) { create(:work, title: identifier, collection_id: restricted_collection.id, owner_user_id: owner.id) }
    let!(:restricted_col_set_work) { create(:work, title: identifier, collection_id: restricted_collection.id, owner_user_id: owner.id) }

    let!(:other_user) { create(:unique_user, :owner) }
    let!(:other_collection) { create(:collection, owner_user_id: other_user.id) }
    let!(:other_restricted_collection) { create(:collection, owner_user_id: other_user.id, restricted: true) }

    let!(:other_public_work) { create(:work, title: identifier, collection_id: other_collection.id, owner_user_id: other_user.id) }
    let!(:other_restricted_work) { create(:work, title: identifier, collection_id: other_restricted_collection.id, owner_user_id: other_user.id) }

    let!(:no_collection_work) { create(:work, title: identifier, collection_id: nil) }

    let(:records) do
      [
        owner,
        collection,
        restricted_collection,
        docset,
        restricted_docset,
        public_work,
        restricted_work,
        restricted_col_public_set_work,
        restricted_col_set_work,
        other_user,
        other_collection,
        other_restricted_collection,
        other_public_work,
        other_restricted_work,
        no_collection_work
      ]
    end

    before(:each) do
      stub_const('ELASTIC_ENABLED', true)

      WorksIndex.purge
      records.each(&:save!)

      restricted_work.update_column(:searchable_metadata, identifier)
      docset.works << restricted_col_public_set_work
      restricted_docset.works << restricted_col_set_work

      WorksIndex.import [
        restricted_work.reload,
        restricted_col_public_set_work.reload,
        restricted_col_set_work.reload
      ]
    end

    after(:each) do
      stub_const('ELASTIC_ENABLED', true)

      records.reverse.each(&:destroy!)
      WorksIndex.purge
    end

    describe '#self.es_search' do
      let(:user) { nil }

      let(:es_search) { described_class.es_search(query: identifier, user: user, is_public: true) }

      context 'when not logged in' do
        it 'returns correct work ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              public_work.id,
              restricted_col_public_set_work.id,
              other_public_work.id
            ]
          )
        end
      end

      context 'when logged in as owner' do
        let(:user) { owner }

        it 'returns correct work ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              public_work.id,
              restricted_work.id,
              restricted_col_public_set_work.id,
              restricted_col_set_work.id,
              other_public_work.id
            ]
          )
        end
      end

      context 'when logged in as other_user and is blocked on public_collection' do
        let(:user) { other_user }

        before do
          collection.blocked_users << other_user
        end

        it 'returns correct work ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              restricted_col_public_set_work.id,
              other_public_work.id,
              other_restricted_work.id
            ]
          )
        end
      end
    end
  end
end
