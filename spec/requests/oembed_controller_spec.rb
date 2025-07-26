require 'spec_helper'

describe OembedController do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, is_active: true) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }

  describe '#show' do
    context 'when requesting JSON format for a collection' do
      let(:collection_url) { "#{request.protocol}#{request.host}/#{owner.slug}/#{collection.slug}" }
      let(:action_path) { oembed_path(url: collection_url, format: 'json') }

      before do
        # Mock the request object for URL parsing
        allow(controller).to receive(:request).and_return(double(
          host: 'example.com',
          protocol: 'http://',
          host_with_port: 'example.com'
        ))
      end

      it 'returns JSON oEmbed response' do
        get action_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response['version']).to eq('1.0')
        expect(json_response['type']).to eq('rich')
        expect(json_response['provider_name']).to eq('FromThePage')
      end
    end

    context 'when requesting invalid URL' do
      let(:invalid_url) { 'https://external-site.com/path' }
      let(:action_path) { oembed_path(url: invalid_url, format: 'json') }

      it 'returns bad request' do
        get action_path

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end