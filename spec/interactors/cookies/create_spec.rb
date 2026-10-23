require 'spec_helper'

describe Cookies::Create do
  let(:cookies) { ActionDispatch::Cookies::CookieJar.new(nil) }
  let(:privacy_preference_params) do
    {
      analytics: true,
      marketing: true
    }
  end
  let(:user) { nil }

  let(:result) do
    described_class.new(cookies: cookies, privacy_preference_params: privacy_preference_params, user: user).call
  end

  it 'updates cookies' do
    expect(result.success?).to be_truthy
    expect(result.cookies[:cookies_recorded]).to be_truthy
    expect(result.cookies[:cookies_analytics]).to be_truthy
    expect(result.cookies[:cookies_marketing]).to be_truthy
  end

  context 'when logged in' do
    let!(:user) { create(:unique_user) }

    it 'updates cookies and privacy_preference' do
      expect(result.success?).to be_truthy
      expect(result.cookies[:cookies_recorded]).to be_truthy
      expect(result.cookies[:cookies_analytics]).to be_truthy
      expect(result.cookies[:cookies_marketing]).to be_truthy

      expect(user.reload.privacy_preference).to have_attributes(
        recorded: true,
        analytics: true,
        marketing: true
      )
    end
  end
end
