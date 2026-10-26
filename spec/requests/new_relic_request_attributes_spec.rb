require 'spec_helper'

RSpec.describe NewRelicRequestAttributes do
  let(:recorded) { [] }
  let(:session_key) { Rails.application.config.session_options[:key].to_s }
  let(:fingerprint_ua) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' }

  before do
    stub_const('NewRelic::Agent', Module.new) unless defined?(::NewRelic::Agent)
    allow(::NewRelic::Agent).to receive(:add_custom_attributes) { |attrs| recorded << attrs }
  end

  def attributes
    recorded.last
  end

  context 'with an anonymous request from a self-declared crawler' do
    it 'tags the request as a bot' do
      get new_user_session_path, headers: { 'User-Agent' => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' }

      expect(attributes).to include(request_kind: 'bot', logged_in: false, owner: false, has_session_cookie: false)
    end
  end

  context 'with the anonymous macOS Chrome fingerprint' do
    it 'tags the request as suspect when there is no session cookie' do
      get new_user_session_path, headers: { 'User-Agent' => fingerprint_ua }

      expect(attributes[:request_kind]).to eq('suspect')
    end

    it 'treats the same user agent as human once it carries a session cookie' do
      get new_user_session_path, headers: { 'User-Agent' => fingerprint_ua, 'Cookie' => "#{session_key}=abc" }

      expect(attributes).to include(request_kind: 'human', has_session_cookie: true)
    end
  end

  context 'with a signed-in owner' do
    let(:owner) { create(:unique_user, :owner) }

    before { login_as owner }

    it 'tags the request as a logged-in human owner' do
      get dashboard_path, headers: { 'User-Agent' => fingerprint_ua }

      expect(attributes).to include(request_kind: 'human', logged_in: true, owner: true)
    end
  end

  context 'when the agent raises' do
    it 'does not break the request' do
      allow(::NewRelic::Agent).to receive(:add_custom_attributes).and_raise(StandardError, 'boom')
      get new_user_session_path

      expect(response).to have_http_status(:ok)
    end
  end
end
