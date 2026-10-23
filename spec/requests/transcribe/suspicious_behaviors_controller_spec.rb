require 'spec_helper'

describe Transcribe::SuspiciousBehaviorsController do
  let!(:user) { create(:unique_user) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }

  describe '#create' do
    let(:action_path) { transcribe_suspicious_behaviors_path(collection_id: collection.id, page_id: page.id) }
    let(:params) do
      {
        suspicious_behavior: {
          behavior_type: 'large_paste',
          content: 'a' * 50
        }
      }
    end

    let(:subject) { post action_path, params: params }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders status' do
      login_as user
      subject
      expect(response).to have_http_status(:ok)
    end

    context 'invalid params' do
      let(:params) do
        {
          suspicious_behavior: {
            extra_params: 'invalid'
          }
        }
      end

      it 'renders status' do
        login_as user
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
