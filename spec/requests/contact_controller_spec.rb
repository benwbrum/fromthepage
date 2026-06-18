require 'spec_helper'

RSpec.describe ContactController do
  include ApplicationHelper
  include ContactHelper

  describe '#form' do
    it 'renders with a valid token' do
      get contact_path(token: contact_form_token)

      expect(response).to have_http_status(:ok)
    end

    it 'raises routing error with an invalid token' do
      expect do
        get contact_path(token: 'invalid')
      end.to raise_error(ActionController::RoutingError)
    end
  end

  describe '#send_email' do
    let(:delivery) { instance_double(ActionMailer::MessageDelivery, deliver!: true) }

    it 'sends contact mail when the dynamic email param is present' do
      expect(ContactMailer).to receive(:contact).with(
        first_name: 'Ada',
        last_name: 'Lovelace',
        email: 'ada@example.com',
        reason: 'Question',
        more: 'More details'
      ).and_return(delivery)

      post send_contact_email_path, params: {
        first_name: 'Ada',
        last_name: 'Lovelace',
        email_param => 'ada@example.com',
        reason: 'Question',
        more: 'More details'
      }

      expect(response).to have_http_status(:ok)
    end

    it 'does not send contact mail when the dynamic email param is blank' do
      expect(ContactMailer).not_to receive(:contact)

      post send_contact_email_path, params: { email_param => '' }

      expect(response).to have_http_status(:ok)
    end
  end
end
