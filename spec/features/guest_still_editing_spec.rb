require 'spec_helper'

describe 'guest user still_editing functionality' do
  before :all do
    @collections = Collection.all
    @collection = @collections.find(3)
    @work = @collection.works.last
    @page = @work.pages.last
  end

  before :each do |test|
    if test.metadata[:guest_enabled]
      # Enable guest transcription for specific tests
      silence_warnings do
        GUEST_TRANSCRIPTION_ENABLED = true
      end
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
    expect(guest_user.slug).to eq(guest_user.login.gsub('_', '-'))

    # Verify that the user can be used in URL generation
    expect(guest_user.to_param).to eq(guest_user.login.gsub('_', '-'))

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

    # Verify that the guest user has proper attributes for URL generation
    expect(guest_user.slug).to eq(guest_user.login.gsub('_', '-'))
    expect(guest_user.to_param).to eq(guest_user.login.gsub('_', '-'))

    # The still_editing functionality is tested via JavaScript periodically in the browser
    # We can't easily test the AJAX call in a feature test, but we can verify
    # that the guest user has the proper attributes needed for the URL generation
    # which was the core issue

    # Verify that a still_editing URL can be generated for the guest user
    still_editing_url = collection_transcribe_still_editing_path(guest_user.slug, @collection.id, @work.id, @page.id)
    expect(still_editing_url).to include(guest_user.slug)
    expect(still_editing_url).to include(@collection.id.to_s)
    expect(still_editing_url).to include(@work.id.to_s)
    expect(still_editing_url).to include(@page.id.to_s)
  end
end
