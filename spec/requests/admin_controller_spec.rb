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

  describe '#uploads' do
    let(:action_path) { admin_uploads_path }
    let(:subject) { get action_path }

    it 'renders for admin' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:uploads)
    end

    context 'with search parameter' do
      let!(:searchable_user) { create(:unique_user, login: 'searchable_user', display_name: 'Searchable User') }
      let!(:searchable_upload) { create(:document_upload, collection: collection, user: searchable_user) }
      let!(:other_user) { create(:unique_user, login: 'other_user', display_name: 'Other User') }
      let!(:other_upload) { create(:document_upload, collection: collection, user: other_user) }

      it 'filters uploads by user login' do
        login_as admin
        get action_path, params: { search: 'searchable' }
        expect(response).to have_http_status(:ok)
        expect(assigns(:document_uploads)).to include(searchable_upload)
        expect(assigns(:document_uploads)).not_to include(other_upload)
      end

      it 'filters uploads by user display name' do
        login_as admin
        get action_path, params: { search: 'Searchable' }
        expect(response).to have_http_status(:ok)
        expect(assigns(:document_uploads)).to include(searchable_upload)
        expect(assigns(:document_uploads)).not_to include(other_upload)
      end
    end
  end

  describe '#solid_queue' do
    # Test for MissionControl UI
    let!(:owner) { create(:unique_user, :owner) }
    let(:subject) { get mission_control_jobs_path }

    it 'redirects for non-admin users' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to('/dashboard')
    end

    it 'renders status and template for admin' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('mission_control/jobs/queues/index')
    end
  end
end
