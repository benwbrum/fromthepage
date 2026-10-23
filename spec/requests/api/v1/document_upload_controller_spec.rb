require 'spec_helper'

describe Api::V1::DocumentUploadController do
  let!(:owner) { create(:unique_user, :with_api_key, :owner) }
  let(:headers) { { 'Authorization': "Bearer #{owner.api_key}" } }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  describe '#start' do
    let(:zip_file) { Rack::Test::UploadedFile.new(Rails.root.join('test_data/uploads/ladi_fixture.zip'), 'application/zip') }
    let(:action_path) { api_v1_document_upload_start_path(collection_slug: collection.slug) }
    let(:params) { { file: zip_file } }

    subject { post action_path, params: params, headers: headers }

    context 'when collection exists and user is owner' do
      before do
        allow_any_instance_of(DocumentUpload).to receive(:submit_process)
      end

      it 'renders status 202 and json with id and status' do
        subject

        expect(response).to have_http_status(:accepted)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        body = JSON.parse(response.body)
        expect(body['id']).to be_present
        expect(body['status']).to be_present
        expect(body['status_uri']).to be_present
      end

      it 'records the upload_file_size' do
        subject

        body = JSON.parse(response.body)
        upload = DocumentUpload.find(body['id'])
        expect(upload.upload_file_size).to eq(zip_file.size)
      end
    end

    context 'when collection does not exist' do
      let(:action_path) { api_v1_document_upload_start_path(collection_slug: 'no-such-slug') }

      it 'renders status 404' do
        subject

        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when user is not authorized' do
      let!(:other_owner) { create(:unique_user, :with_api_key, :owner) }
      let!(:collection) { create(:collection, owner_user_id: other_owner.id) }

      it 'renders status 403' do
        subject

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when no file is provided' do
      let(:params) { {} }

      it 'renders status 400' do
        subject

        expect(response).to have_http_status(:bad_request)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'without api_key' do
      let(:headers) { {} }

      it 'renders status 401' do
        subject

        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when targeting a document set slug' do
      let!(:document_set) { create(:document_set, owner_user_id: owner.id, collection: collection) }
      let(:action_path) { api_v1_document_upload_start_path(collection_slug: document_set.slug) }

      before do
        allow_any_instance_of(DocumentUpload).to receive(:submit_process)
      end

      it 'renders status 202 and assigns the document set' do
        subject

        expect(response).to have_http_status(:accepted)
        body = JSON.parse(response.body)
        upload = DocumentUpload.find(body['id'])
        expect(upload.document_set).to eq(document_set)
        expect(upload.collection).to eq(collection)
      end
    end
  end

  describe '#status' do
    let!(:document_upload) { create(:document_upload, collection: collection, user: owner) }
    let(:action_path) { api_v1_document_upload_status_path(document_upload_id: document_upload.id) }

    subject { get action_path, headers: headers }

    context 'when document upload exists' do
      it 'renders status 200 and json' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        body = JSON.parse(response.body)
        expect(body['id']).to eq(document_upload.id)
        expect(body['status']).to be_present
        expect(body['status_uri']).to be_present
      end
    end

    context 'when document upload does not exist' do
      let(:action_path) { api_v1_document_upload_status_path(document_upload_id: -1) }

      it 'renders status 403' do
        subject

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'without api_key' do
      let(:headers) { {} }

      it 'renders status 401' do
        subject

        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end
end
