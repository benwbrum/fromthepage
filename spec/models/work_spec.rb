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
  describe '#segmentation_candidates?' do
    let(:work) { create(:work, owner_user_id: 1) }

    it "returns false when no pages have been flagged as first-page candidates" do
      create(:page, work_id: work.id, position: 1, is_first_page_candidate: false)
      create(:page, work_id: work.id, position: 2, is_first_page_candidate: nil)

      expect(work.segmentation_candidates?).to be false
    end

    it "returns true when at least one page is flagged as a first-page candidate" do
      create(:page, work_id: work.id, position: 1, is_first_page_candidate: false)
      create(:page, work_id: work.id, position: 2, is_first_page_candidate: true)

      expect(work.segmentation_candidates?).to be true
    end
  end

  describe '#finished_ai_work_metadata_by_engine' do
    let(:work) { create(:work, owner_user_id: 1) }

    it 'returns an empty hash when there are no finished ai work metadata drafts' do
      create(:ai_work_metadata, work_id: work.id, status: :new)

      expect(work.finished_ai_work_metadata_by_engine).to eq({})
      expect(work.ai_metadata_draft_available?).to be false
    end

    it 'groups the most recent finished draft per engine' do
      create(
        :ai_work_metadata,
        work_id: work.id,
        model: 'gemini-3.7-flash',
        status: :finished,
        created_at: 1.day.ago
      )
      latest_gemini = create(
        :ai_work_metadata,
        work_id: work.id,
        model: 'gemini-3.7-flash',
        status: :finished,
        created_at: 1.hour.ago
      )
      claude_draft = create(
        :ai_work_metadata,
        work_id: work.id,
        model: 'claude-3-5-sonnet',
        status: :finished
      )
      create(:ai_work_metadata, work_id: work.id, model: 'gemini-3.7-flash', status: :error)

      by_engine = work.finished_ai_work_metadata_by_engine

      expect(by_engine.keys).to contain_exactly('gemini', 'claude')
      expect(by_engine['gemini']).to eq(latest_gemini)
      expect(by_engine['claude']).to eq(claude_draft)
      expect(work.ai_metadata_draft_available?).to be true
    end
  end

  describe '#page_segmentation_enabled?' do
    let(:owner) { create(:unique_user, :owner, segmentation_enabled: true) }
    let(:collection) do
      create(:collection, owner_user_id: owner.id, data_entry_type: 'text', works: [])
    end
    let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }

    it 'is true when AI has flagged a first-page candidate' do
      create(:page, work_id: work.id, position: 1)
      create(:page, work_id: work.id, position: 2, is_first_page_candidate: true)

      expect(work.page_segmentation_enabled?).to be true
    end

    it 'is true when the collection lets transcribers split works' do
      collection.update!(allow_transcriber_segmentation: true)
      create(:page, work_id: work.id, position: 1)

      expect(work.page_segmentation_enabled?).to be true
    end

    it 'is false with no candidates and the collection setting off' do
      create(:page, work_id: work.id, position: 1)

      expect(work.page_segmentation_enabled?).to be false
    end

    it 'is false when the owner account is not opted into segmentation' do
      owner.update!(segmentation_enabled: false)
      create(:page, work_id: work.id, position: 1)
      create(:page, work_id: work.id, position: 2, is_first_page_candidate: true)

      expect(work.reload.page_segmentation_enabled?).to be false
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

  describe 'title validation' do
    it 'allows titles up to the expanded database limit' do
      work = build(:work, title: 'a' * 1028)

      expect(work).to be_valid
    end

    it 'rejects titles longer than the expanded database limit' do
      work = build(:work, title: 'a' * 1029)

      expect(work).not_to be_valid
      expect(work.errors[:title]).to include('is too long (maximum is 1028 characters)')
    end
  end

  context 'es_search' do
    let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

    let!(:owner) { create(:unique_user, :owner) }
    let!(:collection) { create(:collection, owner_user_id: owner.id) }
    let!(:restricted_collection) { create(:collection, owner_user_id: owner.id, visibility: :private) }
    let!(:docset) { create(:document_set, collection_id: restricted_collection.id, owner_user_id: owner.id, visibility: :public) }
    let!(:restricted_docset) { create(:document_set, collection_id: restricted_collection.id, owner_user_id: owner.id, visibility: :private) }

    let!(:public_work) { create(:work, title: identifier, collection_id: collection.id, owner_user_id: owner.id) }
    let!(:restricted_work) { create(:work, collection_id: restricted_collection.id, owner_user_id: owner.id) }

    let!(:restricted_col_public_set_work) { create(:work, title: identifier, collection_id: restricted_collection.id, owner_user_id: owner.id) }
    let!(:restricted_col_set_work) { create(:work, title: identifier, collection_id: restricted_collection.id, owner_user_id: owner.id) }

    let!(:other_user) { create(:unique_user, :owner) }
    let!(:other_collection) { create(:collection, owner_user_id: other_user.id) }
    let!(:other_restricted_collection) { create(:collection, owner_user_id: other_user.id, visibility: :private) }

    let!(:other_public_work) { create(:work, title: identifier, collection_id: other_collection.id, owner_user_id: other_user.id) }
    let!(:other_restricted_work) { create(:work, title: identifier, collection_id: other_restricted_collection.id, owner_user_id: other_user.id) }

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
        other_restricted_work
      ]
    end

    before(:each) do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

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
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      records.reverse.each(&:destroy!)
      WorksIndex.purge

      VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
    end

    describe '#self.es_search' do
      let(:user) { nil }

      let(:es_search) { described_class.es_search(query: identifier, user: user, is_public: true) }

      context 'when not logged in' do
        it 'returns correct work ids' do
          expect(es_search.pluck('_id').map(&:to_i)).to match_array(
            [
              public_work.id,
              restricted_col_public_set_work.id,
              other_public_work.id
            ]
          )
        end

        context 'when indexing work with collection' do
          it 'returns correct work ids' do
            expect(es_search.pluck('_id').map(&:to_i)).to match_array(
              [
                public_work.id,
                restricted_col_public_set_work.id,
                other_public_work.id
              ]
            )
          end
        end
      end

      context 'when logged in as owner' do
        let(:user) { owner }

        it 'returns correct work ids' do
          expect(es_search.pluck('_id').map(&:to_i)).to match_array(
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
          expect(es_search.pluck('_id').map(&:to_i)).to match_array(
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
