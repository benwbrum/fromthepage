require 'spec_helper'

RSpec.describe StaticController do
  let(:user) { create(:unique_user) }

  describe '#landing_page' do
    it 'renders for anonymous visitors' do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it 'redirects admins to the admin dashboard' do
      login_as create(:unique_user, :admin)

      get root_path

      expect(response).to redirect_to(admin_path)
    end

    it 'redirects owners to the owner dashboard' do
      login_as create(:unique_user, :owner)

      get root_path

      expect(response).to redirect_to(dashboard_owner_path)
    end

    it 'redirects regular users to the watchlist dashboard' do
      login_as user

      get root_path

      expect(response).to redirect_to(dashboard_watchlist_path)
    end

    it 'renders for signed-in users when the logo param is present' do
      login_as user

      get landing_path, params: { logo: 'true' }

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#metadata' do
    it 'renders the metadata yaml as plain text' do
      get static_metadata_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/plain')
      expect(response.body).to include('title:')
    end
  end

  describe 'public landing pages' do
    it 'renders signup' do
      get signup_path

      expect(response).to have_http_status(:ok)
    end

    it 'renders transcription archives' do
      get special_collections_path

      expect(response).to have_http_status(:ok)
    end

    it 'renders public libraries' do
      get public_libraries_path

      expect(response).to have_http_status(:ok)
    end

    it 'renders digital scholarship' do
      get digital_scholarship_path

      expect(response).to have_http_status(:ok)
    end

    it 'renders state archives' do
      get state_archives_path

      expect(response).to have_http_status(:ok)
    end
  end
end
