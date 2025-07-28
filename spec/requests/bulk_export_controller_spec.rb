require 'spec_helper'

describe BulkExportController do
  let!(:admin) { create(:admin) }
  let!(:regular_user) { create(:user) }
  let!(:collection) { create(:collection, owner_user_id: admin.id) }
  let!(:bulk_export) { create(:bulk_export, collection: collection, user: admin) }

  describe '#index' do
    let(:action_path) { bulk_export_index_path }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when logged in as regular user' do
      login_as regular_user
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

  describe '#show' do
    let(:action_path) { bulk_export_show_path(bulk_export_id: bulk_export.id) }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when logged in as regular user' do
      login_as regular_user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders when logged in as admin' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end
  end

  describe '#download' do
    let(:action_path) { bulk_export_download_path(bulk_export_id: bulk_export.id) }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when logged in as regular user' do
      login_as regular_user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when logged in as admin' do
      before { login_as admin }

      it 'processes the download request' do
        # Note: The actual download behavior will depend on the export status
        # but at least we verify that admin authentication passes
        subject
        expect(response).not_to redirect_to(dashboard_path)
      end
    end
  end
end