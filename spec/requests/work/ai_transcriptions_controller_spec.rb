require 'spec_helper'

describe Work::AiTranscriptionsController do
  before do
    Current.user = owner
  end

  let!(:user) { create(:unique_user) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:admin) { create(:unique_user, :admin) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, owner_user_id: owner.id, pages: [], collection: collection) }

  let!(:page) { create(:page, work: work) }
  let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, status: :processing, source_text: nil, reasoning: nil) }

  let!(:work_2) { create(:work, owner_user_id: owner.id, pages: [], collection: collection) }

  let!(:page_2) { create(:page, work: work_2) }
  let!(:ai_transcription_2) { create(:ai_transcription, page_id: page_2.id, status: :processing, source_text: nil, reasoning: nil) }

  describe '#edit' do
    let(:action_path) { edit_collection_work_ai_transcriptions_path(owner, collection, work) }

    let(:subject) { get action_path }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when accessed by owner' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end

      context 'with more than 1 result' do
        let!(:page_2) { create(:page, work: work) }
        let!(:ai_transcription_2) { create(:ai_transcription, page_id: page_2.id, status: :finished, source_text: nil, reasoning: nil) }

        let!(:page_3) { create(:page, work: work) }
        let!(:ai_transcription_3) { create(:ai_transcription, page_id: page_3.id, status: :error, source_text: nil, reasoning: nil) }

        let!(:page_4) { create(:page, work: work) }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:edit)
        end
      end

      context 'when the collection has no metadata fields configured' do
        it 'disables the edit-metadata-after-split checkbox and shows the setup message' do
          login_as owner
          subject

          expect(response.body).to include('disabled="disabled" type="checkbox" value="1" name="work[edit_metadata_after_split]"')
          expect(response.body).to include('Please enable and configure metadata creation under')
          expect(response.body).to include(%(href="#{edit_tasks_collection_path(owner, collection)}">Task Configuration</a>))
        end
      end

      context 'when the collection has metadata fields configured' do
        before do
          collection.update!(data_entry_type: 'text_and_metadata')
          create(:transcription_field, :as_metadata, collection: collection)
        end

        it 'enables the edit-metadata-after-split checkbox and hides the setup message' do
          login_as owner
          subject

          expect(response.body).not_to include('disabled="disabled" type="checkbox" value="1" name="work[edit_metadata_after_split]"')
          expect(response.body).not_to include('Please enable and configure metadata creation under')
        end
      end

      context 'with failed transcriptions' do
        let!(:failed_page) { create(:page, work: work, title: 'Failed Work Page') }
        let!(:failed_ai_transcription) do
          create(:ai_transcription, page_id: failed_page.id, status: :error, metadata: { error_message: 'RECITATION' })
        end

        it 'renders failed transcription details' do
          login_as owner
          subject

          expect(response.body).to include('Failed transcription errors')
          expect(response.body).to include('RECITATION')
          expect(response.body).to include('Failed Work Page')
          expect(response.body).to include(collection_display_page_path(owner, collection, work, failed_page))
        end
      end
    end

    context 'when accessed by non-owner user' do
      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when accessed by admin' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#create' do
    let(:action_path) { collection_ai_transcriptions_path(owner, collection) }

    let(:subject) { post action_path, as: :turbo_stream }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:create)
    end

    context 'with errors' do
      before do
        stub_const('AiTranscription::DEFAULT_MODEL', nil)
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:create)
      end
    end
  end

  describe '#segmentation_setting' do
    let(:action_path) { segmentation_setting_collection_work_ai_transcriptions_path(owner, collection, work) }

    let(:subject) { patch action_path, params: { work: { edit_metadata_after_split: '1' } }, as: :turbo_stream }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:segmentation_setting)
    end

    it 'persists the setting on the work' do
      login_as owner

      expect { subject }.to change { work.reload.edit_metadata_after_split? }.from(false).to(true)
    end

    context 'when unchecking the setting' do
      let(:subject) { patch action_path, params: { work: { edit_metadata_after_split: '0' } }, as: :turbo_stream }

      before { work.update!(edit_metadata_after_split: true) }

      it 'persists the setting as false' do
        login_as owner

        expect { subject }.to change { work.reload.edit_metadata_after_split? }.from(true).to(false)
      end
    end

    context 'when accessed by non-owner user' do
      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe '#update' do
    let(:action_path) { collection_work_ai_transcriptions_path(owner, collection, work) }

    let(:subject) { put action_path, as: :turbo_stream }

    let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, status: :error, source_text: nil, reasoning: nil) }

    let!(:page_2) { create(:page, work: work) }
    let!(:ai_transcription_2) { create(:ai_transcription, page_id: page_2.id, status: :finished, source_text: nil, reasoning: nil) }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:update)
    end

    context 'with errors' do
      let(:result) { instance_double('Result', success?: false) }
      let(:service) { instance_double(AiTranscription::BulkRetry, call: result) }

      before do
        allow(AiTranscription::BulkRetry).to receive(:new).and_return(service)
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update)
      end
    end
  end
end
