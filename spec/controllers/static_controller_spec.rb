require 'spec_helper'

describe StaticController, type: :controller do
  describe 'GET #faq' do
    it 'renders the FAQ page successfully' do
      get :faq
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:faq)
    end
  end

  describe 'GET #about' do
    it 'renders the about page successfully' do
      get :about
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:about)
    end
  end

  describe 'FAQ page content' do
    it 'includes browser compatibility section' do
      get :faq
      expect(response.body).to include('Browser Compatibility Issues')
      expect(response.body).to include('Connection is not private')
      expect(response.body).to include('Avast')
      expect(response.body).to include('Safari')
    end

    it 'includes helpful links for Avast configuration' do
      get :faq
      expect(response.body).to include('support.avast.com')
      expect(response.body).to include('scan-exclusions')
    end

    it 'provides alternative browser suggestions' do
      get :faq
      expect(response.body).to include('Chrome or Firefox')
    end
  end
end