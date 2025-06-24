require 'spec_helper'

describe AdminController do
  let!(:admin) { create(:admin) }
  let!(:collection) { create(:collection, owner_user_id: admin.id) }
  let!(:document_upload) { create(:document_upload, collection: collection, user: admin) }
  let!(:flag) { create(:flag) }
  let!(:existing_user) { create(:user) }

  let!(:welcome_block) do
    PageBlock.create!(controller: 'admin', view: 'new_owner', html: 'Welcome')
  end
  let!(:flag_deny_block) do
    PageBlock.create!(controller: 'admin', view: 'flag_denylist', html: '')
  end
  let!(:email_deny_block) do
    PageBlock.create!(controller: 'admin', view: 'email_denylist', html: '')
  end

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
      expect(response.body).to include(existing_user.login)
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

  describe 'admin tabs' do
    before { login_as admin }

    shared_examples 'an admin tab' do |path, template|
      it "responds to #{template}" do
        get path
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(template)
      end
    end

    it_behaves_like 'an admin tab', admin_owner_list_path, :owner_list
    it_behaves_like 'an admin tab', admin_moderation_path, :moderation
    it_behaves_like 'an admin tab', admin_uploads_path, :uploads
    it 'responds to exports' do
      get bulk_export_index_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    it 'responds to searches' do
      get admin_searches_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:searches)
    end

    it 'responds to logfile' do
      get admin_tail_logfile_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:tail_logfile)
    end

    it 'responds to settings' do
      get admin_settings_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:settings)
    end

    it 'responds to tags' do
      get admin_tags_index_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:tag_list)
    end
  end
end
