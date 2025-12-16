require 'spec_helper'

describe Collection::AiTranscriptionsController do
  before do
    Current.user = owner
  end

  let!(:user) { create(:unique_user) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:admin) { create(:unique_user, :admin) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  describe '#edit' do
    let(:action_path) { edit_collection_ai_transcriptions_path(owner, collection) }

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
  end

  describe '#update' do
    let(:action_path) { collection_ai_transcriptions_path(owner, collection) }

    let(:subject) { put action_path, as: :turbo_stream }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:update)
    end
  end
end
