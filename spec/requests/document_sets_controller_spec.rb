require 'spec_helper'

describe DocumentSetsController do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id) }

  describe '#index' do
    let(:params) { {} }
    let(:action_path) { document_sets_path(collection_id: collection.id) }

    subject { get action_path, params: params }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'with search filter' do
      let(:work) { create(:work, collection: collection) }
      let(:params) { { search: work.title } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#settings' do
    let(:action_path) { collection_settings_path(owner, document_set) }

    subject { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:settings)
    end
  end

  describe '#settings_privacy' do
    let(:action_path) { collection_settings_privacy_path(owner, document_set) }

    subject { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:settings_privacy)
    end
  end

  describe '#settings_works' do
    let(:action_path) { collection_settings_works_path(owner, document_set) }
    let(:params) { {} }

    subject { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:settings_works)
    end

    context 'with filters' do
      let(:work) { create(:work, collection: collection) }
      subject { get action_path, params: params, as: :turbo_stream }

      context 'search filter' do
        let(:params) { { search: work.title, order: 'ASC' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:settings_works)
        end
      end

      context 'show included filter' do
        let(:params) { { show: 'included', order: 'DESC' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:settings_works)
        end
      end

      context 'show not_included filter' do
        let(:params) { { show: 'not_included', order: 'DESC' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:settings_works)
        end
      end
    end
  end

  describe '#update' do
    let(:scope) { nil }
    let(:params) { {} }

    let(:action_path) { document_set_path(document_set, collection_id: document_set.slug, scope: scope) }

    subject { put action_path, params: params, as: :turbo_stream }

    context 'when scope edit' do
      let(:scope) { 'edit' }

      let(:params) do
        {
          document_set: {
            title: 'New title',
            description: 'New description',
            picture: Rack::Test::UploadedFile.new(Rails.root.join('test_data/images/pages/sanskrit.jpg'), 'images/jpg')
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_general)
      end
    end

    context 'when scope edit_privacy' do
      let(:scope) { 'edit_privacy' }

      let(:params) do
        {
          document_set: {
            visibility: 'public'
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_privacy)
      end
    end
  end

  describe '#destroy' do
    let(:action_path) { document_sets_destroy_path(document_set_id: document_set.id) }

    subject { delete action_path }

    it 'renders status and template' do
      login_as owner
      subject

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end
end
