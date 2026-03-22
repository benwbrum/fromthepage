require 'spec_helper'

describe UserController do
  before do
    Current.user = owner
  end

  let(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  describe '#search' do
    let(:action_path) { owner_search_path(owner) }
    let(:params) { { term: page.title } }

    let(:subject) { get action_path, params: params }

    before do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      CollectionsIndex.import collection.reload
      WorksIndex.import collection.works
      PagesIndex.import collection.works.flat_map(&:pages)
    end

    after do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:search)
    end
  end

  describe '#profile' do
    context 'when user is deleted and visitor is not logged in' do
      let(:deleted_user) { create(:user, deleted: true, slug: 'deleted-user') }

      it 'does not raise 500 error for site visitors accessing deleted user' do
        # Simulate site visitor (not logged in)
        expect {
          get user_profile_path(deleted_user.slug)
        }.not_to raise_error

        # Should redirect to dashboard with notice
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to be_present
      end
    end

    context 'when user is deleted and visitor is admin' do
      let(:admin_user) { create(:admin) }
      let(:deleted_user) { create(:user, deleted: true, slug: 'deleted-user-admin-test') }

      it 'allows admin to view deleted user profile' do
        login_as admin_user

        get user_profile_path(deleted_user.slug)

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:profile)
      end
    end

    context 'when owner has document_sets_on_owner_page flag set' do
      let(:gri_owner) { create(:unique_user, :owner, document_sets_on_owner_page: true) }
      let!(:gri_collection) { create(:collection, owner_user_id: gri_owner.id, supports_document_sets: true, intro_block: '<p>Full HTML <a href="#">description</a></p>') }
      let!(:document_set) { create(:document_set, collection_id: gri_collection.id, owner_user_id: gri_owner.id, visibility: :public) }

      it 'does not show document sets on the owner profile page' do
        get user_profile_path(gri_owner.slug)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(document_set.title)
      end

      it 'shows full HTML description without truncation on the owner profile page' do
        get user_profile_path(gri_owner.slug)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<a href="#">description</a>')
      end
    end
  end

  describe '#update' do
    let(:action_path) { user_update_path(user_slug: owner.slug) }
    let(:params) do
      {
        user: {
          real_name: 'New Real Name',
          notifications: {
            user_activity: '0'
          },
          privacy_preferences: {
            analytics: '1',
            marketing: '1'
          }
        }
      }
    end

    let(:subject) { patch action_path, params: params }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:found)
      expect(owner.reload.notification).to have_attributes(
        user_activity: false
      )
      expect(owner.reload.privacy_preference).to have_attributes(
        recorded: true,
        analytics: true,
        marketing: true
      )
    end
  end
end
