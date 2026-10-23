require 'spec_helper'

describe Api::ApiController do
  describe '#help' do
    let(:action_path) { api_path }

    let(:subject) { get action_path }

    it 'renders status and plain_text' do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
    end
  end
end
