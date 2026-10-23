require 'spec_helper'

describe CookiesController do
  describe '#new' do
    let(:action_path) { new_cooky_path }
    let(:params) { {} }

    let(:subject) { get action_path, params: params, as: :turbo_stream }

    it 'renders status and template' do
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end

    context 'when expanded' do
      let(:params) { { expand: true } }

      it 'renders status and template' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    let(:action_path) { cookies_path }
    let(:params) do
      {
        privacy_preference: {
          analytics: true,
          marketing: true
        }
      }
    end

    let(:subject) { post action_path, params: params, as: :turbo_stream }

    it 'renders status and template' do
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:create)

      expect(cookies[:cookies_recorded]).to be_truthy
      expect(cookies[:cookies_analytics]).to be_truthy
      expect(cookies[:cookies_marketing]).to be_truthy
    end

    context 'when logged in' do
      let!(:owner) { create(:unique_user, :owner) }
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:create)

        expect(cookies[:cookies_recorded]).to be_truthy
        expect(cookies[:cookies_analytics]).to be_truthy
        expect(cookies[:cookies_marketing]).to be_truthy
      end
    end
  end
end
