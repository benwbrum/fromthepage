require 'spec_helper'

describe BulkExportController do
  let!(:admin) { create(:admin) }
  let!(:regular_user) { create(:user) }
  let!(:collection_owner) { create(:user) }
  let!(:collection_collaborator) { create(:user) }
  let!(:non_owner_user) { create(:user) }
  let!(:collection) { create(:collection, owner_user_id: collection_owner.id, collaborators: [collection_collaborator]) }
  let!(:other_collection) { create(:collection, owner_user_id: regular_user.id) }
  let!(:bulk_export) { create(:bulk_export, collection: collection, user: collection_owner) }
  let!(:other_bulk_export) { create(:bulk_export, collection: other_collection, user: regular_user) }

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

    it 'redirects when logged in as collection owner' do
      login_as collection_owner
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when logged in as collection collaborator' do
      login_as collection_collaborator
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

    it 'redirects when logged in as regular user (non-owner)' do
      login_as non_owner_user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders when logged in as collection owner' do
      login_as collection_owner
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    it 'renders when logged in as collection collaborator' do
      login_as collection_collaborator
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

    it 'redirects when collection owner tries to access bulk export they do not own' do
      login_as collection_owner
      get bulk_export_show_path(bulk_export_id: other_bulk_export.id)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when collection collaborator tries to access bulk export for collection they do not collaborate on' do
      login_as collection_collaborator
      get bulk_export_show_path(bulk_export_id: other_bulk_export.id)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
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

    it 'redirects when logged in as regular user (non-owner)' do
      login_as non_owner_user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when logged in as collection owner' do
      before { login_as collection_owner }

      it 'processes the download request' do
        # Note: The actual download behavior will depend on the export status
        # but at least we verify that owner authentication passes
        subject
        expect(response).not_to redirect_to(dashboard_path)
      end
    end

    context 'when logged in as collection collaborator' do
      before { login_as collection_collaborator }

      it 'processes the download request' do
        # Note: The actual download behavior will depend on the export status
        # but at least we verify that collaborator authentication passes
        subject
        expect(response).not_to redirect_to(dashboard_path)
      end
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

    it 'redirects when collection owner tries to download bulk export they do not own' do
      login_as collection_owner
      get bulk_export_download_path(bulk_export_id: other_bulk_export.id)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when collection collaborator tries to download bulk export for collection they do not collaborate on' do
      login_as collection_collaborator
      get bulk_export_download_path(bulk_export_id: other_bulk_export.id)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end
  end
end