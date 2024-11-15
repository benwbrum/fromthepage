require 'spec_helper'
require 'fileutils'
require 'zip'

describe Api::V1::BulkExportController do
  let!(:owner) { create(:unique_user, :with_api_key, :owner) }
  let(:headers) { { 'Authorization': "Bearer #{owner.api_key}" } }

  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  describe '#index' do
    let(:action_path) { api_v1_bulk_export_path }
    let(:params) { { collection_slug: collection.slug } }

    let(:subject) { get action_path, params: params, headers: headers }

    context 'with collection_slug param' do
      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end

      context 'when collection does not exist' do
        let(:params) { { collection_slug: SecureRandom.hex(4) } }

        it 'renders status and json' do
          subject

          expect(response).to have_http_status(:not_found)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end
    end

    context 'without collection_slug param' do
      let(:params) { {} }

      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'without api_key' do
      let(:headers) { {} }

      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#start' do
    let(:action_path) { api_v1_bulk_export_start_path(collection_slug: collection.slug) }

    let(:subject) { post action_path, headers: headers }

    context 'when collection can show to user' do
      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:accepted)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when collection cannot show to user' do
      let!(:other_owner) { create(:unique_user, :with_api_key, :owner) }
      let!(:collection) { create(:collection, owner_user_id: other_owner.id, restricted: true) }

      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'without api_key' do
      let(:headers) { {} }

      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#status' do
    let!(:bulk_export) { create(:bulk_export, collection_id: collection.id, user_id: owner.id) }
    let(:action_path) { api_v1_bulk_export_status_path(bulk_export_id: bulk_export.id) }

    let(:subject) { get action_path, headers: headers }

    context 'when bulk export exists' do
      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when bulk export does not exist' do
      let(:action_path) { api_v1_bulk_export_status_path(bulk_export_id: SecureRandom.hex(4)) }

      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'without api_key' do
      let(:headers) { {} }

      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#download' do
    let!(:bulk_export) { create(:bulk_export, :finished, collection_id: collection.id, user_id: owner.id) }
    let(:action_path) { api_v1_bulk_export_download_path(bulk_export_id: bulk_export.id) }

    let(:subject) { get action_path, headers: headers }

    context 'when bulk export exists' do
      context 'when bulk export is finished' do
        before do
          FileUtils.mkdir_p(bulk_export.zip_file_path)
          Zip::File.open(bulk_export.zip_file_name, Zip::File::CREATE) do |_zipfile|
            # Create temp empty zip
          end
        end

        it 'renders status' do
          subject

          expect(response).to have_http_status(:ok)
        end
      end

      context 'when bulk export is cleaned' do
        let!(:bulk_export) { create(:bulk_export, :cleaned, collection_id: collection.id, user_id: owner.id) }

        it 'renders status and json' do
          subject

          expect(response).to have_http_status(:gone)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end

      context 'when bulk export has error' do
        let!(:bulk_export) { create(:bulk_export, :error, collection_id: collection.id, user_id: owner.id) }

        it 'renders status and json' do
          subject

          expect(response).to have_http_status(:gone)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end

      context 'when bulk export has other statuses' do
        let!(:bulk_export) { create(:bulk_export, :queued, collection_id: collection.id, user_id: owner.id) }

        it 'renders status and json' do
          subject

          expect(response).to have_http_status(:conflict)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end
    end

    context 'when bulk export does not exist' do
      let(:action_path) { api_v1_bulk_export_download_path(bulk_export_id: SecureRandom.hex(4)) }

      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'without api_key' do
      let(:headers) { {} }

      it 'renders status and json' do
        subject

        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end
end
