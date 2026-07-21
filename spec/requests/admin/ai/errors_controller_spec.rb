require 'spec_helper'

describe Admin::Ai::ErrorsController do
  let!(:user) { create(:unique_user) }
  let!(:admin) { create(:unique_user, :admin) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }
  let!(:ai_transcription_error) { create(:ai_transcription, page_id: page.id, status: :error, metadata: { 'error_message' => 'Test error' }) }
  let!(:ai_transcription_finished) { create(:ai_transcription, page_id: page.id, status: :finished) }

  describe '#index' do
    let(:action_path) { admin_ai_errors_path }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when not admin' do
      login_as user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders status and template' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    it 'only shows ai_transcription errors' do
      login_as admin
      subject
      expect(assigns(:ai_transcriptions)).to include(ai_transcription_error)
      expect(assigns(:ai_transcriptions)).not_to include(ai_transcription_finished)
    end

    it 'orders newest first' do
      login_as admin
      subject
      expect(assigns(:ai_transcriptions).first).to eq(ai_transcription_error)
    end
  end

  describe '#show' do
    let(:action_path) { admin_ai_error_path(ai_transcription_error) }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when not admin' do
      login_as user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders status and template' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    it 'assigns ai_transcription, page, work, collection' do
      login_as admin
      subject
      expect(assigns(:ai_transcription)).to eq(ai_transcription_error)
      expect(assigns(:page)).to eq(page)
      expect(assigns(:work)).to eq(work)
      expect(assigns(:collection)).to eq(collection)
    end

    context 'when record is not an error' do
      let(:action_path) { admin_ai_error_path(ai_transcription_finished) }

      it 'redirects to 404 for non-error record' do
        login_as admin
        subject
        expect(response).to redirect_to('/404')
      end
    end
  end
end
