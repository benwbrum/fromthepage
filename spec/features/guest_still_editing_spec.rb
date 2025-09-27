require 'spec_helper'

describe 'guest user still_editing functionality' do
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

  it 'guest users should have proper login and slug for URL generation' do
    # Simulate creating a guest user like the application does
    guest_user = User.new { |user| user.guest = true }
    timestamp_rand = "#{Time.now.to_f}#{rand(99999)}".gsub('.', '')
    guest_user.email = "guest_#{timestamp_rand}@example.com"
    guest_user.login = "guest_#{timestamp_rand}"
    guest_user.save(validate: false)

    # Check that the guest user has proper attributes for URL generation
    expect(guest_user.login).not_to be_nil
    expect(guest_user.login).to start_with('guest_')
    expect(guest_user.slug).to eq(guest_user.login)

    # Verify that the user can be used in URL generation
    expect(guest_user.to_param).to eq(guest_user.login)

    guest_user.destroy
  end

  it 'guest user can successfully call still_editing endpoint', :guest_enabled do
    visit collection_display_page_path(@collection.owner, @collection, @work, @page.id)
    page.find('.tabs').click_link('Transcribe')
    click_button('Transcribe as guest')

    # Get the guest user that was created
    guest_user = User.where(guest: true).last
    expect(guest_user).not_to be_nil
    expect(guest_user.login).not_to be_nil

    # Simulate the still_editing AJAX call that would happen from the frontend
    # This should not fail due to slug issues
    post collection_transcribe_still_editing_path(guest_user.slug, @collection.id, @work.id, @page.id)
    expect(response.status).to eq(200)

    # Verify that the page was updated with editing information
    @page.reload
    expect(@page.edit_started_by_user_id).to eq(guest_user.id)
    expect(@page.edit_started_at).not_to be_nil
    expect(@page.edit_started_at).to be_within(5.seconds).of(Time.now)
  end
end
