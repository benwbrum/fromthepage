require 'spec_helper'

describe Collection::AiWorkMetadataController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:admin) { create(:unique_user, :admin) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:metadata_field) { create(:transcription_field, :as_metadata, :text_field, collection_id: collection.id) }
  let!(:work) { create(:work, owner_user_id: owner.id, pages: [], collection: collection) }

  describe '#show' do
    let!(:ai_work_metadata) { create(:ai_work_metadata, work_id: work.id, status: :finished, metadata_json: { metadata_field.id.to_s => 'Some Title' }) }

    let(:action_path) { collection_ai_work_metadatum_path(owner, collection, ai_work_metadata) }

    let(:subject) { get action_path }

    it 'redirects when not signed in' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when accessed by owner' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to include('Some Title')
      end
    end

    context 'when accessed by non-owner user' do
      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_path(owner, collection))
      end
    end

    context 'when accessed by admin' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end
  end

  describe '#create' do
    let(:action_path) { collection_ai_work_metadata_path(owner, collection) }

    let(:subject) { post action_path, as: :turbo_stream }

    it 'renders status and template and queues generation for works without a draft' do
      login_as owner
      get '/feature/ai_work_metadata/enable'

      expect { subject }.to have_enqueued_job(AiWorkMetadata::BulkGenerateJob)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:create)
      expect(AiWorkMetadata.where(work_id: work.id)).to exist
    end

    context 'when accessed by non-owner user' do
      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
      end
    end

    context 'with errors' do
      before do
        login_as owner
        get '/feature/ai_work_metadata/enable'
        allow_any_instance_of(AiWorkMetadata::BulkCreate).to receive(:perform).and_raise(ArgumentError, 'boom')
      end

      it 'renders status and template' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:create)
      end
    end

    context 'when the feature is disabled' do
      it 'does not enable metadata drafts for a collection without them' do
        login_as owner

        expect { subject }.not_to change(AiWorkMetadata, :count)
        expect(AiWorkMetadata::BulkGenerateJob).not_to have_been_enqueued
        expect(response).to have_http_status(:not_found)
      end

      it 'allows metadata drafts to run when they are already enabled for the collection' do
        create(:ai_work_metadata, work: work, status: :error)
        login_as owner

        expect { subject }.to have_enqueued_job(AiWorkMetadata::BulkGenerateJob)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
