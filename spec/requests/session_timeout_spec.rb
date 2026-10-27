require 'spec_helper'

describe 'Session inactivity timeout' do
  include ActiveSupport::Testing::TimeHelpers

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  let(:transcribe_path) { collection_transcribe_page_path(owner, collection, work, page) }
  let(:still_editing_path) { collection_transcribe_still_editing_path(owner.slug, collection.id, work.id, page.id) }

  before do
    Current.user = owner
  end

  after do
    travel_back
  end

  it 'uses a 30 minute timeout' do
    expect(User.timeout_in).to eq(30.minutes)
  end

  context 'when signed in without remember me' do
    before do
      login_as owner
      get transcribe_path
      expect(response).to have_http_status(:ok)
    end

    it 'keeps the session alive while the user is active' do
      travel 20.minutes
      get transcribe_path
      expect(response).to have_http_status(:ok)

      travel 20.minutes
      get transcribe_path
      expect(response).to have_http_status(:ok)
    end

    it 'signs the user out after 30 minutes of inactivity' do
      travel 31.minutes
      get transcribe_path

      expect(response).to redirect_to(transcribe_path)
      expect(flash[:alert]).to eq(I18n.t('devise.failure.timeout'))

      follow_redirect!
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a timed-out user to a public page with only the timeout message' do
      public_path = collection_path(owner, collection)
      travel 31.minutes
      get public_path

      expect(response).to redirect_to(public_path)
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('devise.failure.timeout'))
      expect(response.body).not_to include('flash-timedout')
    end

    it 'does not let still_editing polling keep an idle session alive' do
      travel 20.minutes
      get still_editing_path, xhr: true
      expect(response).to have_http_status(:ok)

      travel 11.minutes
      get still_editing_path, xhr: true
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when signed in with remember me' do
    before do
      post user_session_path, params: { user: { login_id: owner.login, password: 'password', remember_me: '1' } }
    end

    it 'does not time out while the remember me cookie is valid' do
      travel 31.minutes
      get transcribe_path

      expect(response).to have_http_status(:ok)
    end
  end
end
