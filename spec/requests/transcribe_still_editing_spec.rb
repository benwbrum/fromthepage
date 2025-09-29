# Request spec to verify still_editing endpoint works with guest users

require 'spec_helper'

describe 'TranscribeController still_editing endpoint' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  before :each do |test|
    if test.metadata[:guest_enabled]
      # Enable guest transcription for specific tests
      silence_warnings do
        GUEST_TRANSCRIPTION_ENABLED = true
      end
    end
  end

  describe 'GET still_editing' do
    context 'when user is a guest', :guest_enabled do
      it 'should successfully update page editing status' do
        # Create a guest user with proper login
        guest_user = User.new(guest: true)
        timestamp_rand = "#{Time.now.to_f}#{rand(99999)}".gsub('.', '')
        guest_user.email = "guest_#{timestamp_rand}@example.com"
        guest_user.login = "guest_#{timestamp_rand}"
        guest_user.save(validate: false)

        # Call the still_editing endpoint with proper route parameters and session
        action_path = collection_transcribe_still_editing_path(guest_user.slug, collection.id, work.id, page.id)
        get action_path, params: {}, session: { guest_user_id: guest_user.id }

        expect(response).to have_http_status(:ok)

        # Verify that the page was updated with guest user's editing info
        page.reload
        expect(page.edit_started_by_user_id).to eq(guest_user.id)
        expect(page.edit_started_at).not_to be_nil
        expect(page.edit_started_at).to be_within(5.seconds).of(Time.now)

        guest_user.destroy
      end
    end

    context 'when user is not signed in and not a guest' do
      it 'should return 401 unauthorized' do
        # Call without any session or authentication
        action_path = collection_transcribe_still_editing_path('nonexistent', collection.id, work.id, page.id)
        get action_path

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to eq('session expired')
      end
    end

    context 'when user is signed in' do
      it 'should successfully update page editing status' do
        login_as owner

        action_path = collection_transcribe_still_editing_path(owner.slug, collection.id, work.id, page.id)
        get action_path

        expect(response).to have_http_status(:ok)

        # Verify that the page was updated with user's editing info
        page.reload
        expect(page.edit_started_by_user_id).to eq(owner.id)
        expect(page.edit_started_at).not_to be_nil
        expect(page.edit_started_at).to be_within(5.seconds).of(Time.now)
      end
    end
  end
end
