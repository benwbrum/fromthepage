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
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      ArticlesIndex.purge
      records.each(&:save!)
    end

    after(:each) do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      records.reverse.each(&:destroy!)
      ArticlesIndex.purge

      VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
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

  describe '#possible_duplicates' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id) }

    def make_article(title)
      create(:article, title: title, collection: collection)
    end

    context 'with a name containing short initials (e.g. "F. R. Calvert")' do
      it 'does not return false positives from single-letter initials' do
        subject_article = make_article('F. R. Calvert')
        calvert_george  = make_article('Calvert, George')
        smith_robert    = make_article('Smith, Robert')

        duplicates = subject_article.possible_duplicates

        expect(duplicates).to include(calvert_george)
        expect(duplicates).not_to include(smith_robert)
      end
    end

    context 'when the title contains a short abbreviation like "Fr." (2 chars)' do
      it 'does not match articles that only share the short abbreviation as a substring' do
        # "Fr. Calvert" - old algorithm searched for "Fr" which matched
        # "Frederick", "Alfred", etc. via LIKE '%Fr%'
        subject_article = make_article('Fr. Calvert')
        # These should NOT be duplicates – they only contain "Fr" as a substring
        frederick_smith  = make_article('Frederick Smith')
        alfred_johnson   = make_article('Alfred Johnson')
        # This SHOULD be a duplicate – it shares the significant word "Calvert"
        calvert_george   = make_article('Calvert, George')

        duplicates = subject_article.possible_duplicates

        expect(duplicates).to include(calvert_george)
        expect(duplicates).not_to include(frederick_smith)
        expect(duplicates).not_to include(alfred_johnson)
      end
    end

    context 'when two articles share a meaningful word' do
      it 'finds articles that contain the shared word as a whole word' do
        subject_article = make_article('John Smith')
        smith_mary      = make_article('Smith, Mary')
        john_calvert    = make_article('John Calvert')

        duplicates = subject_article.possible_duplicates

        expect(duplicates).to include(smith_mary)
        expect(duplicates).to include(john_calvert)
      end
    end

    context 'when another article only shares the word as a substring' do
      it 'does not return the article as a duplicate (whole-word matching)' do
        subject_article = make_article('John Smith')
        # "Smithson" contains "Smith" as a substring but not as a whole word
        smithson_william = make_article('Smithson, William')

        duplicates = subject_article.possible_duplicates

        expect(duplicates).not_to include(smithson_william)
      end
    end

    context 'when the title has no words with 4 or more alphabetic characters' do
      it 'returns an empty list' do
        subject_article = make_article('J. R. B.')
        other_article = make_article('Some Random Article Title')

        duplicates = subject_article.possible_duplicates

        expect(duplicates).to be_empty
        expect(duplicates).not_to include(other_article)
      end
    end

    context 'when articles are in different collections' do
      it 'does not return articles from a different collection' do
        other_collection = create(:collection, owner_user_id: owner.id)
        subject_article = make_article('John Smith')
        other_coll_article = create(:article, title: 'John Smith', collection: other_collection)

        expect(subject_article.possible_duplicates).not_to include(other_coll_article)
      end
    end

    context 'when articles share multiple words' do
      it 'returns articles sharing multiple words before single-word matches' do
        subject_article    = make_article('Frederick Calvert')
        both_words         = make_article('Calvert, Frederick')
        only_calvert       = make_article('Calvert, George')
        only_frederick     = make_article('Frederick Smith')

        duplicates = subject_article.possible_duplicates

        expect(duplicates).to include(both_words)
        expect(duplicates).to include(only_calvert)
        expect(duplicates).to include(only_frederick)
        # The article sharing both words should appear first (higher priority).
        # The include assertions above guarantee non-nil index lookups below.
        both_words_idx     = duplicates.index(both_words)
        only_calvert_idx   = duplicates.index(only_calvert)
        only_frederick_idx = duplicates.index(only_frederick)
        expect(both_words_idx).to be < only_calvert_idx
        expect(both_words_idx).to be < only_frederick_idx
      end
    end
  end
end
