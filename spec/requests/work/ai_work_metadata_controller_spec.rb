require 'spec_helper'

describe Work::AiWorkMetadataController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, owner_user_id: owner.id, collection: collection) }
  let!(:text_field) do
    create(:transcription_field, :as_metadata, :text_field,
           label: 'Title', collection: collection, position: 1, line_number: 1)
  end

  let!(:ai_work_metadata) { create(:ai_work_metadata, work_id: work.id, status: :processing, metadata_json: nil, reasoning: nil) }

  describe '#show' do
    let(:action_path) { collection_work_ai_work_metadatum_path(owner, collection, work, ai_work_metadata) }

    let(:subject) { get action_path }

    it 'redirects when unauthorized' do
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
      end
    end
  end

  describe '#create' do
    let(:action_path) { collection_work_ai_work_metadata_path(owner, collection, work) }

    let(:subject) { post action_path, as: :turbo_stream }

    it 'redirects when unauthorized' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when accessed by owner' do
      before do
        login_as owner
        get '/feature/ai_work_metadata/enable'
      end

      it 'renders status and template' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:create)
      end

      it 'triggers a bulk generate job for this work only' do
        expect(AiWorkMetadata::BulkGenerateJob).to receive(:perform_later).with(
          collection_id: collection.id,
          user_id: owner.id,
          scope: { work_ids: [work.id] }
        )

        subject
      end

      context 'when the collection has no metadata fields' do
        let!(:text_field) { nil }
        let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }

        it 'still renders the create template' do
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:create)
        end
      end
    end

    context 'when the feature is disabled' do
      it 'does not enable metadata drafts for a collection without them' do
        login_as owner
        ai_work_metadata.destroy!

        expect { subject }.not_to change(AiWorkMetadata, :count)
        expect(AiWorkMetadata::BulkGenerateJob).not_to have_been_enqueued
        expect(response).to have_http_status(:not_found)
      end

      it 'allows metadata drafts to run when they are already enabled for the collection' do
        login_as owner

        expect { subject }.to have_enqueued_job(AiWorkMetadata::BulkGenerateJob)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
