require 'spec_helper'

RSpec.describe ContactController, type: :request do
  include ApplicationHelper
  include ContactHelper

  describe 'GET #form' do
    context 'with valid token' do
      it 'renders the contact form' do
        token = contact_form_token
        get "/#{token}/contact"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid token' do
      it 'raises RoutingError for invalid token' do
        expect {
          get "/invalid_token/contact"
        }.to raise_error(ActionController::RoutingError, 'Not Found')
      end

      it 'raises RoutingError for empty token' do
        expect {
          get "//contact"
        }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'with expired token' do
      it 'accepts tokens from previous hour' do
        # Mock time to generate a token for previous hour
        past_time = Time.now - 3600 # 1 hour ago
        allow(Time).to receive(:now).and_return(past_time)
        old_token = contact_form_token
        
        # Reset time to current
        allow(Time).to receive(:now).and_call_original
        
        # The old token should still be valid
        get "/#{old_token}/contact"
        expect(response).to have_http_status(:ok)
      end

      it 'rejects tokens from 2+ hours ago' do
        # Mock time to generate a token for 2 hours ago
        past_time = Time.now - 7200 # 2 hours ago
        allow(Time).to receive(:now).and_return(past_time)
        old_token = contact_form_token
        
        # Reset time to current
        allow(Time).to receive(:now).and_call_original
        
        # The old token should be invalid
        expect {
          get "/#{old_token}/contact"
        }.to raise_error(ActionController::RoutingError, 'Not Found')
      end
    end
  end

  describe 'POST #send_email' do
    let(:valid_token) { contact_form_token }
    let(:email_field) { email_param }
    let(:valid_params) do
      {
        first_name: 'John',
        last_name: 'Doe', 
        email_field => 'john@example.com',
        reason: 'Product question',
        more: 'I have a question about your product'
      }
    end

    before do
      # Set up the form first to establish the token
      get "/#{valid_token}/contact"
    end

    it 'sends email with valid parameters' do
      expect(ContactMailer).to receive(:contact).with(
        first_name: 'John',
        last_name: 'Doe',
        email: 'john@example.com',
        reason: 'Product question',
        more: 'I have a question about your product'
      ).and_return(double(deliver!: true))

      post '/contact/send', params: valid_params
      expect(response).to have_http_status(:ok)
    end

    it 'does not send email with blank email' do
      expect(ContactMailer).not_to receive(:contact)
      
      invalid_params = valid_params.merge(email_field => '')
      post '/contact/send', params: invalid_params
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'ApplicationHelper#contact_form_token' do
    it 'generates a token with consistent length' do
      token = contact_form_token
      expect(token.length).to be >= 6
    end

    it 'generates different tokens for different hours' do
      current_time = Time.now
      next_hour = current_time + 3600
      
      current_token = contact_form_token
      
      allow(Time).to receive(:now).and_return(next_hour)
      next_token = contact_form_token
      
      expect(current_token).not_to eq(next_token)
    end
  end

  describe 'ApplicationHelper#valid_contact_form_token?' do
    it 'validates current hour token' do
      token = contact_form_token
      expect(valid_contact_form_token?(token)).to be true
    end

    it 'validates previous hour token' do
      past_time = Time.now - 3600
      allow(Time).to receive(:now).and_return(past_time)
      old_token = contact_form_token
      
      allow(Time).to receive(:now).and_call_original
      
      expect(valid_contact_form_token?(old_token)).to be true
    end

    it 'rejects tokens from 2+ hours ago' do
      past_time = Time.now - 7200
      allow(Time).to receive(:now).and_return(past_time)
      old_token = contact_form_token
      
      allow(Time).to receive(:now).and_call_original
      
      expect(valid_contact_form_token?(old_token)).to be false
    end

    it 'rejects invalid tokens' do
      expect(valid_contact_form_token?('invalid')).to be false
      expect(valid_contact_form_token?('')).to be false
      expect(valid_contact_form_token?(nil)).to be false
    end
  end
end