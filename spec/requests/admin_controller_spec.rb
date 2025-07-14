require 'spec_helper'

describe AdminController do
  let!(:admin) { create(:unique_user, :admin) }
  let!(:collection) { create(:collection, owner_user_id: admin.id) }
  let!(:document_upload) { create(:document_upload, collection: collection, user: admin) }
  let!(:flag) { create(:flag) }

  describe '#index' do
    let(:action_path) { admin_path }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders when logged in as admin' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  describe '#user_list' do
    let(:action_path) { admin_user_list_path }
    let(:subject) { get action_path }

    it 'renders for admin' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:user_list)
    end
  end

  describe '#flag_list' do
    let(:action_path) { admin_flag_list_path }
    let(:subject) { get action_path }

    it 'renders for admin' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:flag_list)
    end
  end

  describe '#delete_upload' do
    let(:action_path) { admin_delete_upload_path(id: document_upload.id) }
    let(:subject) { get action_path }

    it 'redirects after deletion' do
      login_as admin
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(admin_uploads_path)
    end
  end
end
