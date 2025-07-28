require 'spec_helper'

describe OembedController do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, is_active: true) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }

  describe '#show' do
    context 'when requesting JSON format for a collection' do
      let(:collection_url) { "http://www.example.com/#{owner.slug}/#{collection.slug}" }
      let(:action_path) { oembed_path(url: collection_url, format: 'json') }

      it 'returns JSON oEmbed response' do
        get action_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response['version']).to eq('1.0')
        expect(json_response['type']).to eq('rich')
        expect(json_response['provider_name']).to eq('FromThePage')
        expect(json_response['title']).to eq(collection.title)
        expect(json_response['author_name']).to eq(owner.display_name)
        expect(json_response['html']).to include(collection.title)
        expect(json_response['html']).to include('Transcription project by')
        expect(json_response['html']).to include('FromThePage')
        expect(json_response['width']).to eq(600)
        expect(json_response['height']).to eq(400)
      end
    end

    context 'when requesting XML format for a collection' do
      let(:collection_url) { "http://www.example.com/#{owner.slug}/#{collection.slug}" }
      let(:action_path) { oembed_path(url: collection_url, format: 'xml') }

      it 'returns XML oEmbed response' do
        get action_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/xml')
        expect(response.body).to include('<oembed>')
        expect(response.body).to include('<provider-name>FromThePage</provider-name>')
        expect(response.body).to include('<version>1.0</version>')
      end
    end

    context 'when requesting JSON format for a work' do
      let(:work_url) { "http://www.example.com/#{owner.slug}/#{collection.slug}/#{work.slug}" }
      let(:action_path) { oembed_path(url: work_url, format: 'json') }

      it 'returns JSON oEmbed response with work data' do
        get action_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response['version']).to eq('1.0')
        expect(json_response['type']).to eq('rich')
        expect(json_response['provider_name']).to eq('FromThePage')
        expect(json_response['title']).to eq(work.title)
        expect(json_response['author_name']).to eq(owner.display_name)
        expect(json_response['html']).to include(work.title)
        expect(json_response['html']).to include('Document by')
        expect(json_response['html']).to include('FromThePage')
      end
    end

    context 'when requesting JSON format for a page' do
      let(:page_url) { "http://www.example.com/#{owner.slug}/#{collection.slug}/#{work.slug}/display/#{page.id}" }
      let(:action_path) { oembed_path(url: page_url, format: 'json') }

      it 'returns JSON oEmbed response with page data' do
        get action_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response['version']).to eq('1.0')
        expect(json_response['type']).to eq('rich')
        expect(json_response['provider_name']).to eq('FromThePage')
        expect(json_response['title']).to include(work.title)
        expect(json_response['author_name']).to eq(owner.display_name)
        expect(json_response['html']).to include(work.title)
        expect(json_response['html']).to include('Page transcription by')
        expect(json_response['html']).to include('FromThePage')
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

    context 'when requesting blank URL' do
      let(:action_path) { oembed_path(url: '', format: 'json') }

      it 'returns bad request' do
        get action_path

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when requesting URL for inactive collection' do
      let!(:inactive_collection) { create(:collection, owner_user_id: owner.id, is_active: false) }
      let(:collection_url) { "http://www.example.com/#{owner.slug}/#{inactive_collection.slug}" }
      let(:action_path) { oembed_path(url: collection_url, format: 'json') }

      it 'returns not found' do
        get action_path

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when requesting URL for non-existent content' do
      let(:nonexistent_url) { "http://www.example.com/#{owner.slug}/nonexistent" }
      let(:action_path) { oembed_path(url: nonexistent_url, format: 'json') }

      it 'returns not found' do
        get action_path

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when format is auto-detected from Accept header' do
      let(:collection_url) { "http://www.example.com/#{owner.slug}/#{collection.slug}" }
      let(:action_path) { oembed_path(url: collection_url) }

      it 'returns JSON when Accept header includes application/json' do
        get action_path, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
      end

      it 'returns XML when Accept header does not include application/json' do
        get action_path, headers: { 'Accept' => 'text/html' }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/xml')
      end
    end
  end
end