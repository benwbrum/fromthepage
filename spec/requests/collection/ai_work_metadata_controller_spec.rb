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
        allow_any_instance_of(AiWorkMetadata::BulkCreate).to receive(:perform).and_raise(ArgumentError, 'boom')
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:create)
      end
    end
  end
end
