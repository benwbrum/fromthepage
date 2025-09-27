require 'spec_helper'

# Test for fix to save_transcription error when navigation arrows are used
# after preview/edit sequence without sending page params
describe TranscribeController, 'navigation fix' do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  describe '#save_transcription' do
    let(:action_path) { transcribe_save_transcription_path }
    let(:subject) { patch action_path, params: params }

    context 'when navigation triggers save_transcription without page params' do
      let(:params) do
        {
          page_id: page.id
          # Note: no page params are sent, simulating navigation arrow click
          # after preview/edit sequence that triggers form submission
        }
      end

      it 'handles missing page params gracefully without ArgumentError' do
        login_as owner
        
        # Before the fix, this would raise:
        # ArgumentError: "When assigning attributes, you must pass a hash as an argument"
        # This happened because page_params calls params.require(:page) but params[:page] is nil
        expect { subject }.not_to raise_error

        # Should render the display_page template since there are no actions to perform
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:display_page)
      end
    end

    context 'when navigation triggers save_transcription with empty page params' do
      let(:params) do
        {
          page_id: page.id,
          page: {}
        }
      end

      it 'handles empty page params gracefully' do
        login_as owner
        
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:display_page)
      end
    end
  end
end