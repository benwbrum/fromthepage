require 'spec_helper'

RSpec.describe 'TranscriptionFieldController choose_offset', type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, field_based: true) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:transcription_field) { create(:transcription_field, :as_transcription, :spreadsheet_field, collection: collection) }

  describe '#choose_offset' do
    let(:action_path) { transcription_field_spreadsheet_column_choose_offset_path(transcription_field) }

    it 'renders without raising route generation errors' do
      expect(collection.pages.count).to eq(1)
      login_as owner
      get action_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:choose_offset)
      expect(response.body).to include("/#{work.to_param}/transcribe_monitor/")
    end
  end
end
