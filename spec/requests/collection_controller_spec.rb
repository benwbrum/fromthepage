require 'spec_helper'

describe CollectionController do
  before do
    User.current_user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  describe '#search_users' do
    let(:action_path) { collection_search_users_path(collection_id: collection.slug) }
    let(:params) { { term: 'Search' } }

    let(:subject) { get action_path, params: params }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects' do
      login_as user
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when user_type owner' do
      let(:params) { { term: 'Search', user_type: 'owner' } }

      it 'renders status and json' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when user_type blocked' do
      let(:params) { { term: 'Search', user_type: 'blocked' } }

      it 'renders status and json' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when user_type reviewer' do
      let(:params) { { term: 'Search', user_type: 'blocked' } }

      it 'renders status and json' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when user_type collaborator (default)' do
      let(:params) { { term: 'Search' } }

      it 'renders status and json' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#edit_help' do
    let!(:collection) { create(:collection, owner_user_id: owner.id, transcription_conventions: 'Convention') }
    let(:action_path) { edit_help_collection_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_help)
    end

    context 'when one work with custom transcription convention' do
      let!(:work) { create(:work, collection: collection, owner_user_id: owner.id, transcription_conventions: 'Custom') }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit_help)
      end
    end

    context 'when more than one work with custom transcription convention' do
      let!(:works) do
        create_list(:work, 2, collection: collection, owner_user_id: owner.id, transcription_conventions: 'Custom')
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit_help)
      end
    end
  end
end
