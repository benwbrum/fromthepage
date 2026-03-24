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

  describe '#owner_list' do
    let(:action_path) { admin_owner_list_path }

    it 'renders owner list for admin' do
      login_as admin
      get action_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:owner_list)
    end

    it 'sorts by login ascending' do
      login_as admin
      get action_path, params: { sort: 'login', dir: 'asc' }
      expect(response).to have_http_status(:ok)
    end

    it 'sorts by login descending' do
      login_as admin
      get action_path, params: { sort: 'login', dir: 'desc' }
      expect(response).to have_http_status(:ok)
    end

    it 'sorts by account_type ascending' do
      login_as admin
      get action_path, params: { sort: 'account_type', dir: 'asc' }
      expect(response).to have_http_status(:ok)
    end

    it 'sorts by account_type descending' do
      login_as admin
      get action_path, params: { sort: 'account_type', dir: 'desc' }
      expect(response).to have_http_status(:ok)
    end

    it 'sorts by start_date ascending' do
      login_as admin
      get action_path, params: { sort: 'start_date', dir: 'asc' }
    end

    it 'sorts by paid_date ascending' do
      login_as admin
      get action_path, params: { sort: 'paid_date', dir: 'asc' }
    end


    it 'sorts by last_sign_in_at ascending' do
      login_as admin
      get action_path, params: { sort: 'last_sign_in_at', dir: 'asc' }
      expect(response).to have_http_status(:ok)
    end
  end
end
