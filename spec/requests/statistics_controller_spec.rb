require 'spec_helper'

describe StatisticsController do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  describe '#collection' do
    let(:action_path) { collection_statistics_path(owner, collection) }
    let(:make_request) { get action_path }

    context 'when user is not logged in' do
      it 'renders the statistics page' do
        make_request

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:collection)
      end
    end

    context 'when logged in as owner' do
      it 'renders the statistics page' do
        login_as owner
        make_request

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:collection)
      end
    end

    context 'when logged in as a regular user' do
      it 'renders the statistics page' do
        login_as user
        make_request

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:collection)
      end
    end
  end
end
