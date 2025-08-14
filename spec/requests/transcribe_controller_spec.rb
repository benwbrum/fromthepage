require 'spec_helper'

describe TranscribeController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  describe '#display_page' do
    let(:action_path) { collection_transcribe_page_path(owner, collection, work, page) }
    let(:subject) { get action_path }

    context 'when user is not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when collection is inactive' do
      let!(:user) { create(:unique_user) }

      before do
        collection.update!(is_active: false)
      end

      it 'redirects to collection overview instead of display page' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_path(owner, collection))
      end
    end

    context 'when read-only document set and user is not a collaborator' do
      let!(:document_set) { create(:document_set, :read_only, owner_user_id: owner.id, collection_id: collection.id) }
      let!(:user) { create(:unique_user) }
      let(:action_path) { collection_transcribe_page_path(owner, document_set, work, page) }

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_display_page_path(owner, document_set, work, page))
      end
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:display_page)
    end
  end

  describe '#save_transcription' do
    # TODO: Move logic to interactor for better isolation testing
    # Temporary, do not do this pattern for request tests
    context 'Article rename race check' do
      # Scenario:
      # Article is renamed and rename job is still running.
      # Another user made update to current page
      # while rename job is unfinished
      let!(:page) { create(:page, work: work, source_text: '[[Original]]', source_translation: '[[Original]]') }
      let!(:category) { create(:category) }
      let!(:article) do
        create(:article, title: 'Original', collection: collection, pages: [page], categories: [category])
      end
      let!(:source_article) do
        create(:article, collection: collection.reload)
      end
      let!(:article_article_link) do
        create(:article_article_link, source_article: source_article, target_article: article)
      end

      let(:action_path) do
        collection_oneoff_review_page_save_path(
          user_slug: owner.slug,
          collection_id: collection.slug,
          page_id: page.id
        )
      end

      let(:params) do
        {
          flow: '',
          quality_sampling_id: '',
          page: {
            mark_blank: '0',
            needs_review: '0',
            source_text: '[[Original]] some change'
          },
          save_to_transcribed: '',
          'filter-brightness' => '0',
          'filter-contrast' => '0',
          'filter-threshold' => '0'
        }
      end

      let(:subject) { patch action_path, params: params }

      it 'updates page without losing article links' do
        source_article.update_column(:source_text, '[[Original]]')
        article.update!(title: 'Renamed')

        login_as owner
        subject

        expect(page.reload.source_text).to include('[[Original]] some change')
        expect(page.articles.reload).to include(article)
        expect(article.reload.categories).to include(category)
      end
    end
  end
  
  describe '#help' do
    let(:action_path) { collection_help_page_path(owner, collection, work, page) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:help)
    end
  end
end
