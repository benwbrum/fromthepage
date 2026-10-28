require 'spec_helper'

RSpec.describe 'OmniAuth sign in', type: :request do
  around do |example|
    previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous_forgery_protection
  end

  def form_for_action(action)
    Nokogiri::HTML(response.body).at_css("form[action='#{action}']")
  end

  def token_for(form)
    form.at_css("input[name='authenticity_token']")['value']
  end

  def select_institution(institution)
    get new_user_session_path
    form = form_for_action(registrations_choose_provider_path)
    post registrations_choose_provider_path, params: { authenticity_token: token_for(form) }
    form = form_for_action(registrations_set_provider_path)
    post registrations_set_provider_path, params: { institution: institution, authenticity_token: token_for(form) }
  end

  it 'posts the selected institution to SAML with a CSRF token and a manual fallback' do
    select_institution('harvard')

    form = form_for_action('/users/auth/saml/harvard')
    expect(form['method']).to eq('post')
    expect(form.at_css("input[type='submit']")).to be_present
    expect(response.body).to include("document.getElementById('saml-provider-form').submit()")

    post form['action'], params: { authenticity_token: token_for(form) }
    expect(response).to redirect_to(%r{\Ahttps://fed\.huit\.harvard\.edu/idp/shibboleth})
    expect(response.location).to include('SAMLRequest=')
  end

  it 'rejects a SAML request without a valid CSRF token' do
    select_institution('harvard')

    post '/users/auth/saml/harvard', params: { authenticity_token: 'invalid' }
    expect(response).to redirect_to(new_user_registration_url)
    expect(flash[:error]).to eq(I18n.t('authentication_failed'))
  end

  it 'does not initiate SAML sign in via GET' do
    get '/users/auth/saml/harvard'
    expect(response.location.to_s).not_to include('fed.huit.harvard.edu')
  end

  it 'uses a POST form for Google when enabled' do
    stub_const('ENABLE_GOOGLEOAUTH', true)
    get new_user_registration_path

    form = form_for_action('/users/auth/google_oauth2')
    expect(form['method']).to eq('post')
    expect(token_for(form)).to be_present
  end

  [:get, :post].each do |method|
    it "processes a SAML #{method.upcase} callback through the middleware" do
      user = User.find_by!(login: USER)
      original_test_mode = OmniAuth.config.test_mode
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(provider: 'saml', uid: 'example')
      allow(User).to receive(:from_omniauth).and_return(user)

      public_send(method, '/users/auth/saml/harvard/callback')
      expect(User).to have_received(:from_omniauth).with(hash_including('provider' => 'saml', 'uid' => 'example'))
      expect(response).to be_redirect
    ensure
      OmniAuth.config.test_mode = original_test_mode
      OmniAuth.config.mock_auth.delete(:saml)
    end
  end

  it 'handles a failed SAML callback through the middleware' do
    post '/users/auth/saml/harvard/callback'
    expect(response).to redirect_to(new_user_registration_url)
    expect(flash[:error]).to eq(I18n.t('authentication_failed'))
  end
end
