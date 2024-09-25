require 'spec_helper'

describe DocumentSetsController do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id) }

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

    context 'with search params' do
      let(:work) { create(:work, collection: collection) }
      let(:params) { { search: work.title } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:settings_works)
      end
    end
  end

  describe '#update' do
    let(:params) { {} }
    let(:action_path) { document_set_path(document_set, collection_id: document_set.slug) }
    let(:xhr) { false }

    subject { put action_path, params: params, xhr: xhr }

    context 'image upload' do
      let(:params) do
        {
          document_set: {
            picture: Rack::Test::UploadedFile.new(Rails.root.join('test_data/images/pages/sanskrit.jpg'), 'images/jpg')
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:settings)
      end
    end

    context 'valid params' do
      let(:params) do
        {
          document_set: {
            title: 'New title',
            description: 'New description'
          }
        }
      end
      let(:xhr) { true }

      it 'renders status and json response' do
        login_as owner
        subject
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body, symbolize_names: true)).to include(
          success: true,
          errors: nil,
          updated_field: {
            title: 'New title',
            description: 'New description',
            slug: 'new-title'
          }
        )
      end
    end

    context 'invalid params' do
      let(:params) do
        {
          document_set: {
            title: ''
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:settings)
      end
    end
  end

  describe '#toggle_privacy' do
    let(:action_path) { document_sets_toggle_privacy_path(collection_id: document_set) }

    subject { post action_path }

    it 'renders status and template' do
      login_as owner
      subject

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:settings_privacy)
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
