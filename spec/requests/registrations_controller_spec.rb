require 'spec_helper'

describe 'RegistrationsController' do
  describe 'POST #set_saml' do
    it 'uses a temporary redirect to preserve the request method' do
      post registrations_set_provider_path, params: { institution: 'example-idp' }

      expect(response).to have_http_status(:temporary_redirect)
      expect(response).to redirect_to(user_omniauth_authorize_path('example-idp'))
    end
  end

  describe 'GET /users/sign_up' do
    before do
      stub_const('ENABLE_GOOGLEOAUTH', true)
    end

    it 'renders the Google auth action as a POST form button' do
      get new_user_registration_path

      expect(response.body).to include("action=\"#{user_omniauth_authorize_path(:google_oauth2)}\"")
      expect(response.body).to include('method="post"')
      expect(response.body).not_to include("href=\"#{user_omniauth_authorize_path(:google_oauth2)}\"")
    end
  end
end
