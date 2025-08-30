require 'spec_helper'

describe UserController do
  before do
    Current.user = owner
  end

  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  describe '#search' do
    let(:action_path) { owner_search_path(owner) }
    let(:params) { { term: page.title } }

    let(:subject) { get action_path, params: params }

    before do
      stub_const('ELASTIC_ENABLED', true)

      CollectionsIndex.import collection.reload
      WorksIndex.import collection.works
      PagesIndex.import collection.works.flat_map(&:pages)
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
  end
end
