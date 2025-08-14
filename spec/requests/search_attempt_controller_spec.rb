require 'spec_helper'

describe SearchAttemptController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:xml_text) do
    "<?xml version='1.0' encoding='UTF-8'?><page><p>The quick <unclear> <link link_id='1428965' target_id='62422' target_title='fox'>fox</link> brown </unclear></p></page>"
  end
  let!(:page) { create(:page, work: work, xml_text: xml_text, search_text: "The quick fox brown\n\nfox\n\n") }
  let!(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id, works: [work]) }

  describe '#create' do
    let(:action_path) { search_attempt_index_path }
    let(:params) { {} }
    let(:subject) { post action_path, params: params, as: :turbo_stream }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template('shared/_flash')
    end

    context 'search work' do
      let(:params) do
        {
          work_id: work.id,
          search: 'brown fox'
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(paged_search_path(SearchAttempt.last, format: :html))
      end
    end

    context 'search work' do
      let(:params) do
        {
          work_id: work.id,
          search: 'brown fox'
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(paged_search_path(SearchAttempt.last, format: :html))
      end
    end

    context 'search collection via collection' do
      let(:params) do
        {
          collection_id: collection.id,
          search: 'brown fox'
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(paged_search_path(SearchAttempt.last, format: :html))
      end
    end

    context 'search collection via document_set' do
      let(:params) do
        {
          document_set_id: document_set.id,
          search: 'brown fox'
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(paged_search_path(SearchAttempt.last, format: :html))
      end
    end

    context 'search collection-title via collection' do
      let(:params) do
        {
          collection_id: collection.id,
          search_by_title: collection.title
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(
          collection_path(owner, collection, search_attempt_id: SearchAttempt.last.id, format: :html)
        )
      end
    end

    context 'search collection-title via document_set' do
      let(:params) do
        {
          document_set_id: document_set.id,
          search_by_title: document_set.title
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(
          collection_path(owner, document_set, search_attempt_id: SearchAttempt.last.id, format: :html)
        )
      end
    end

    context 'search findaproject' do
      let(:params) do
        {
          search: collection.title
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(search_attempt_path(SearchAttempt.last, format: :html))
      end
    end
  end

  describe '#show' do
    let(:action_path) { search_attempt_path('invalid-id') }
    let(:subject) { get action_path }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(landing_page_path)
    end

    context 'with valid search attempt' do
      let!(:search_attempt) do
        create(:search_attempt, user_id: owner.id, search_type: 'findaproject', query: 'brown fox')
      end
      let(:action_path) { search_attempt_path(search_attempt.slug) }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end
  end
end
