require 'spec_helper'

describe StaticController do
  describe '#search_help' do
    let(:action_path) { search_help_path }
    let(:subject) { get action_path }

    it 'renders the search help page successfully' do
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:search_help)
    end

    it 'contains expected search help content' do
      subject
      expect(response.body).to include('Search Help')
      expect(response.body).to include('Boolean Operators')
      expect(response.body).to include('Phrase Search')
      expect(response.body).to include('AND Operator')
      expect(response.body).to include('OR Operator')
      expect(response.body).to include('NOT Operator')
      expect(response.body).to include('"Mrs. Alice Mann"')
    end

    it 'includes examples of search queries' do
      subject
      expect(response.body).to include('alice AND mann')
      expect(response.body).to include('alice OR jane')
      expect(response.body).to include('alice NOT jane')
      expect(response.body).to include('mann*')
    end
  end

  describe '#search_help via static scope' do
    let(:action_path) { static_search_help_path }
    let(:subject) { get action_path }

    it 'renders the search help page via static scope' do
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:search_help)
    end
  end
end