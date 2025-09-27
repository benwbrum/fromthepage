require 'spec_helper'

# Test for navigation disabling in preview mode
describe TranscribeController, 'navigation disabled in preview' do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  describe '#save_transcription preview mode' do
    let(:action_path) { transcribe_save_transcription_path }
    let(:params) do
      {
        page_id: page.id,
        page: {
          source_text: 'Test content'
        },
        preview: 'Preview'
      }
    end
    let(:subject) { patch action_path, params: params }

    it 'sets display_context to preview which disables navigation' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:display_page)
      expect(assigns(:display_context)).to eq('preview')
    end
  end
end