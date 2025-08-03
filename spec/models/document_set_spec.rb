require 'spec_helper'

describe DocumentSet do
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

  context 'es_search' do
    let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

    let!(:owner) { create(:unique_user, :owner) }
    let!(:base_collection) { create(:collection, owner_user_id: owner.id) }

    let!(:public_docset) { create(:document_set, title: identifier, collection_id: base_collection.id, owner_user_id: owner.id, visibility: :public) }
    let!(:restricted_docset) { create(:document_set, title: identifier, collection_id: base_collection.id, owner_user_id: owner.id, visibility: :private) }
    let!(:public_updated_to_restricted_docset) { create(:document_set, title: identifier, collection_id: base_collection.id, owner_user_id: owner.id, visibility: :read_only) }

    let!(:other_user) { create(:unique_user, :owner) }
    let!(:other_base_collection) { create(:collection, owner_user_id: other_user.id) }

    let!(:other_public_docset) { create(:document_set, title: identifier, collection_id: other_base_collection.id, owner_user_id: other_user.id, visibility: :public) }
    let!(:other_restricted_docset) { create(:document_set, title: identifier, collection_id: other_base_collection.id, owner_user_id: other_user.id, visibility: :private) }

    # We also query by intro_block, so this tests that
    let!(:no_owner_public_docset) { create(:document_set, description: "<div>#{identifier}</div>", collection_id: other_base_collection.id, owner_user_id: nil, visibility: :public) }

    let(:records) do
      [
        owner,
        base_collection,
        public_docset,
        restricted_docset,
        public_updated_to_restricted_docset,
        other_user,
        other_base_collection,
        other_public_docset,
        other_restricted_docset,
        no_owner_public_docset
      ]
    end

    before(:each) do
      stub_const('ELASTIC_ENABLED', true)

      DocumentSetsIndex.purge
      records.each(&:save!)

      public_updated_to_restricted_docset.update!(visibility: :private)
    end

    after(:each) do
      stub_const('ELASTIC_ENABLED', true)

      records.reverse.each(&:destroy!)
      DocumentSetsIndex.purge
    end

    describe '#self.es_search' do
      let(:user) { nil }

      let(:es_search) { described_class.es_search(query: identifier, user: user, is_public: true) }

      context 'when not logged in' do
        it 'returns correct document_set ids' do
          expect(es_search.pluck("_id")).to match_array(
            [
              "docset-#{public_docset.id}",
              "docset-#{other_public_docset.id}",
              "docset-#{no_owner_public_docset.id}"
            ]
          )
        end
      end

      context 'when logged in as owner' do
        let(:user) { owner }

        it 'returns correct document_set ids' do
          expect(es_search.pluck("_id")).to match_array(
            [
              "docset-#{public_docset.id}",
              "docset-#{restricted_docset.id}",
              "docset-#{public_updated_to_restricted_docset.id}",
              "docset-#{other_public_docset.id}",
              "docset-#{no_owner_public_docset.id}"
            ]
          )
        end
      end

      context 'when logged in as other_user and is blocked on public_collection' do
        let(:user) { other_user }

        before do
          base_collection.blocked_users << other_user
        end

        it 'returns correct document_set ids' do
          expect(es_search.pluck("_id")).to match_array(
            [
              "docset-#{other_public_docset.id}",
              "docset-#{other_restricted_docset.id}",
              "docset-#{no_owner_public_docset.id}"
            ]
          )
        end
      end
    end
  end
end
