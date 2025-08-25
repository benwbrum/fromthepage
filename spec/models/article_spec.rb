require 'spec_helper'

# TODO: We want individual es_search specs for other models as well,
# not just in multi_query_spec
describe Article do
  context 'es_search' do
    let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

    let!(:owner) { create(:unique_user, :owner) }
    let!(:public_collection) { create(:collection, owner_user_id: owner.id) }
    let!(:restricted_collection) { create(:collection, owner_user_id: owner.id, restricted: true) }

    let!(:work_1) { create(:work, collection: public_collection) }
    let!(:page_1) { create(:page, work: work_1) }

    let!(:work_2) { create(:work, collection: restricted_collection) }
    let!(:page_2) { create(:page, work: work_2) }

    let!(:work_3) { create(:work, collection: restricted_collection) }
    let!(:page_3) { create(:page, work: work_3) }

    let!(:public_document_set) do
      create(
        :document_set,
        :public,
        collection_id: restricted_collection.id,
        owner_user_id: owner.id,
        works: [work_3]
      )
    end

    # Belongs to public collection
    let!(:article_1) do
      create(
        :article,
        title: identifier,
        collection: public_collection,
        pages: [page_1],
        created_by_id: owner.id
      )
    end

    # Belongs to private collection
    let!(:article_2) do
      create(
        :article,
        title: identifier,
        collection: restricted_collection,
        pages: [page_2],
        created_by_id: owner.id
      )
    end

    # Belongs to private collection, but belongs to public document_set
    let!(:article_3) do
      create(
        :article,
        title: identifier,
        collection: restricted_collection,
        pages: [page_3],
        created_by_id: owner.id
      )
    end

    let!(:other_user) { create(:unique_user, :owner) }
    let!(:other_public_collection) { create(:collection, owner_user_id: other_user.id) }
    let!(:other_restricted_collection) { create(:collection, owner_user_id: other_user.id, restricted: true) }

    let!(:work_4) { create(:work, collection: other_public_collection) }
    let!(:page_4) { create(:page, work: work_4) }

    let!(:work_5) { create(:work, collection: other_restricted_collection) }
    let!(:page_5) { create(:page, work: work_5) }

    # Belongs to other user public collection
    let!(:article_4) do
      create(
        :article,
        collection: other_public_collection,
        pages: [page_4],
        created_by_id: other_user.id,
        source_text: identifier
      )
    end

    # Belongs to other user private collection
    let!(:article_5) do
      create(
        :article,
        title: identifier,
        collection: other_restricted_collection,
        pages: [page_5],
        created_by_id: other_user.id
      )
    end

    let(:records) do
      [
        owner,
        public_collection,
        restricted_collection,
        work_1,
        page_1,
        work_2,
        page_2,
        work_3,
        page_3,
        public_document_set,
        article_1,
        article_2,
        article_3,
        other_user,
        other_public_collection,
        other_restricted_collection,
        work_4,
        page_4,
        work_5,
        page_5,
        article_4,
        article_5
      ]
    end

    before(:each) do
      stub_const('ELASTIC_ENABLED', true)

      records.each(&:save!)
    end

    after(:each) do
      stub_const('ELASTIC_ENABLED', true)

      records.reverse.each(&:destroy!)
    end

    describe '#self.es_search' do
      let(:user) { nil }

      let(:es_search) { Article.es_search(query: identifier, user: user, is_public: true) }

      context 'when not logged in' do
        it 'returns correct article ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              article_1.id,
              article_3.id,
              article_4.id
            ]
          )
        end
      end

      context 'when logged in as owner' do
        let(:user) { owner }

        it 'returns correct article ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              article_1.id,
              article_2.id,
              article_3.id,
              article_4.id
            ]
          )
        end
      end

      context 'when logged in as other_user and is blocked on public_collection' do
        let(:user) { other_user }

        before do
          public_collection.blocked_users << other_user
        end

        it 'returns correct article ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              article_3.id,
              article_4.id,
              article_5.id
            ]
          )
        end
      end
    end
  end
end
