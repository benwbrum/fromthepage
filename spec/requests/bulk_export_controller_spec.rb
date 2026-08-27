require 'spec_helper'

describe BulkExportController do
  let!(:admin) { create(:unique_user, :admin) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, visibility: :private) }
  let!(:bulk_export) { create(:bulk_export, collection_id: collection.id, user_id: owner.id) }

  describe '#index' do
    let(:action_path) { bulk_export_index_path }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when not admin' do
      login_as owner
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe 'show' do
    let(:action_path) { bulk_export_show_path(bulk_export) }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when not authorized user' do
      login_as user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders when logged in as owner' do
      login_as owner
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    it 'renders when logged in as admin' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end
  end

  describe '#new' do
    let!(:public_collection) { create(:collection, owner_user_id: owner.id, visibility: :public) }
    let!(:public_work) { create(:work, collection: public_collection, owner_user_id: owner.id) }
    let(:action_path) { bulk_export_new_path(public_collection) }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when logged in as non-owner' do
      login_as user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders when logged in as owner' do
      login_as owner
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end

    it 'redirects when logged in as admin (non-owner)' do
      login_as admin
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe '#download' do
    let!(:finished_export) { create(:bulk_export, :finished, collection_id: collection.id, user_id: owner.id) }
    let(:action_path) { bulk_export_download_path(bulk_export_id: finished_export.id) }

    before { login_as owner }

    context 'when zip file exists on disk' do
      before do
        FileUtils.mkdir_p(finished_export.zip_file_path)
        Zip::File.open(finished_export.zip_file_name, create: true) { |_z| }
      end

      after do
        File.delete(finished_export.zip_file_name) if File.exist?(finished_export.zip_file_name)
      end

      it 'sends the file' do
        get action_path
        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Disposition']).to include('fromthepage_export.zip')
      end
    end

    context 'when zip file does not exist on disk' do
      it 'redirects with a flash message instead of raising an error' do
        get action_path
        expect(response).to have_http_status(:redirect)
        expect(flash[:info]).to be_present
      end
    end
  end
end
