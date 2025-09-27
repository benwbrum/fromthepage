# Test to verify still_editing endpoint works with guest users

require 'spec_helper'

describe TranscribeController do
  before :all do
    @collections = Collection.all
    @collection = @collections.find(3) 
    @work = @collection.works.last
    @page = @work.pages.last
  end

  before :each do
    # Enable guest transcription for these tests
    silence_warnings do
      GUEST_TRANSCRIPTION_ENABLED = true
    end
  end

  describe '#still_editing' do
    context 'when user is a guest' do
      it 'should successfully update page editing status' do
        # Create a guest user with proper login
        guest_user = User.new(guest: true)
        timestamp_rand = "#{Time.now.to_f}#{rand(99999)}".gsub('.', '')
        guest_user.email = "guest_#{timestamp_rand}@example.com"
        guest_user.login = "guest_#{timestamp_rand}"
        guest_user.save(validate: false)

        # Set session to simulate guest user session
        session[:guest_user_id] = guest_user.id

        # Call the still_editing endpoint
        get :still_editing, params: { page_id: @page.id }

        expect(response.status).to eq(200)
        
        # Verify that the page was updated with guest user's editing info
        @page.reload
        expect(@page.edit_started_by_user_id).to eq(guest_user.id)
        expect(@page.edit_started_at).not_to be_nil
        expect(@page.edit_started_at).to be_within(5.seconds).of(Time.now)

        guest_user.destroy
      end
    end
    
    context 'when user is not signed in and not a guest' do
      it 'should return 401 unauthorized' do
        # Clear any session data
        session[:guest_user_id] = nil
        
        get :still_editing, params: { page_id: @page.id }
        
        expect(response.status).to eq(401)
        expect(response.body).to eq('session expired')
      end
    end
  end
end