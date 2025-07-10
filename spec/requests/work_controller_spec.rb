require 'spec_helper'

describe WorkController do
  before do
    User.current_user = owner
  end

  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:article) { create(:article, collection: collection, pages: [page]) }

  describe '#edit' do
    let(:action_path) { edit_collection_work_path(owner, collection, work) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit)
    end

    context 'when user is not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is not an owner' do
      let(:user) { User.where(owner: false).first }

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe '#update' do
    let(:action_path) { work_update_path(id: work.id) }
    let(:params) do
      {
        work: {
          title: 'New title',
          description: '<b> New description </b>',
          collection_id: collection.id,
          transcription_conventions: 'New transcription conventions'
        }
      }
    end
    let(:subject) { post action_path, params: params }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(edit_collection_work_path(owner, collection, work.reload))
    end

    context 'when changed collection_id' do
      let!(:collection_2) { create(:collection, owner_user_id: owner.id) }
      let(:params) do
        {
          work: {
            title: 'New title',
            description: '<b> New description </b>',
            collection_id: collection_2.id,
            transcription_conventions: 'New transcription conventions'
          }
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(edit_collection_work_path(owner, collection_2, work.reload))
      end
    end

    context 'failed update' do
      let(:params) do
        {
          work: {
            title: '',
            description: ''
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
      end
    end
  end
end
