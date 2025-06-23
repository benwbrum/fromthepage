require 'spec_helper'

describe HoneypotsController do
  let!(:owner) { create(:unique_user, :owner) }

  describe '#trap' do
    let(:token) { SecureRandom.hex(10) }
    let(:action_path) { honeypot_path(token: token) }
    let(:honeypot_events) { Ahoy::Event.where(name: 'honeypots#trap') }

    let(:subject) { get action_path }

    it 'redirects' do
      events_count = honeypot_events.count
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(landing_page_path)
      expect(honeypot_events.reload.count).to eq(events_count + 1)
    end

    it 'redirects' do
      login_as owner
      events_count = honeypot_events.count
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(landing_page_path)
      expect(honeypot_events.reload.count).to eq(events_count + 1)
    end
  end
end
