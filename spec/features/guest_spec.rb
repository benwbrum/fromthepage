require 'spec_helper'

describe 'guest user actions' do
  GUEST_NAV_HEADING = 'Create An Account'

  before :all do
    @collections = Collection.all
    @collection = @collections.find(3)
    @work = @collection.works.last
    @page = @work.pages.last
    @owner = User.find_by(login: OWNER)
    @admin = User.find_by(login: ADMIN)
  end

  before :each do |test|
    if test.metadata[:guest_enabled]
      # Guest Transcription is no longer the default and is enabled via
      # a global flag in an initializer. To test guest processes,
      # we must enable the flag for those (old) tests. New tests are not
      # be affected.
      silence_warnings do
        GUEST_TRANSCRIPTION_ENABLED = true
      end
    end
  end

  it 'guest transcription route returns 403 by default' do
    page.driver.post("/application/guest_transcription?page_id=#{@page.id}")

    expect(page.status_code).to eq(403)
  end

  it 'does not show `transcribe as guest` by default' do
    visit "/display/display_page?page_id=#{@page.id}"
    page.find('.tabs').click_link('Transcribe')

    expect(page).to have_button('Sign Up Now')
    expect(page).not_to have_button('Transcribe as guest')
  end

  it 'shows `transcribe as guest` when enabled', :guest_enabled do
    visit "/display/display_page?page_id=#{@page.id}"
    page.find('.tabs').click_link('Transcribe')

    expect(page).to have_button('Transcribe as guest')
  end

  it 'tests guest account creation and migration', :guest_enabled do
    visit "/display/display_page?page_id=#{@page.id}"
    page.find('.tabs').click_link('Transcribe')

    # Navbar displays generic sign-in
    expect(page.html).to include('<span>Sign In</span>')
    expect(page.html).to_not include('<big>Signed In As</big>')
    expect(page.html).to_not include("<big>#{GUEST_NAV_HEADING}</big>")

    # Transcription section shows button
    expect(page).to have_button('Transcribe as guest')
    click_button('Transcribe as guest')

    # Button permits Guest to save contributions
    expect(page).to have_button('Save')

    # Navbar displays Guest as user and gives link to create account
    expect(page.html).to include('<small>Guest</small>')
    expect(page.html).to include("<big>#{GUEST_NAV_HEADING}</big>")
    expect(page).to have_link(GUEST_NAV_HEADING)

    # The user is stored as a guest
    @guest = User.last
    expect(@guest.guest).to be true

    # The user can click a link to arrive at the Sign Up form
    first(:link, GUEST_NAV_HEADING).click
    expect(page).to have_content('Sign Up')
  end

  it 'tests guest account transcription', :guest_enabled do
    visit collection_display_page_path(@collection.owner, @collection, @work, @page.id)

    # Transcribe Tab: Becoming a 'guest'
    page.find('.tabs').click_link('Transcribe')
    expect(page).to have_content('Sign In')
    click_button('Transcribe as guest')
    expect(page).to have_content(GUEST_NAV_HEADING)
    expect(page).to have_button('Save')
    @guest = User.last
    expect(@guest.guest).to be true

    # Contribution 1
    fill_in_editor_field 'Guest Transcription 1'
    find('#save_button_top').click
    expect(page).to have_content("You may save up to #{GUEST_DEED_COUNT} transcriptions as a guest.")

    # Versions Tab: check to see what the page versions say
    page.find('.tabs').click_link('Versions')
    expect(page).to have_content('revisions')
    expect(page).to have_link('Guest')

    # Transcribe Tab: Contribution 2
    page.find('.tabs').click_link('Transcribe')
    fill_in_editor_field 'Second Guest Deed'
    find('#save_button_top').click

    # Transcribe Tab: Contribution 3
    fill_in_editor_field 'Third Guest Deed'
    find('#save_button_top').click

    # Convert Account: after 3 transcriptions, the user should be forced to sign up
    expect(page.current_path).to eq new_user_registration_path
    fill_in 'Username', with: 'martha'
    fill_in 'Email Address', with: 'martha@test.com'
    fill_in 'Password', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    fill_in 'Real Name', with: 'Martha'
    click_button('Create Account')
    @user = User.last
    expect(@user.login).to eq('martha')
    expect(@guest.id).to eq(@user.id)
    expect(page.current_path).to eq collection_transcribe_page_path(@collection.owner, @collection, @work, @page.id)

    # Versions tab should now be visible to the signed up user
    expect(page.find('.tabs')).to have_link('Versions')
    page.find('.tabs').click_link('Versions')
    expect(page).to have_link('martha')
  end

  it 'looks at the landing page', :guest_enabled do
    CollectionStatistic.update_recent_statistics
    
    # Ensure margaret has the data needed for landing page
    margaret = User.find_by(login: OWNER)
    margaret.update!(
      owner: true,
      deleted: false,
      account_type: 'Legacy',
      display_name: 'Margaret Reed',
      real_name: 'Margaret Reed'
    )
    
    # Ensure margaret's collection is set up properly
    collection = margaret.collections.first
    if collection
      collection.update!(
        restricted: false,
        is_active: true,
        featured_at: 1.week.ago
      )
    end
    
    visit landing_page_path
    expect(page.find('.maincol')).to have_link(@owner.display_name)
    page.find('.maincol').first('a', text: @owner.display_name).click
    expect(page.find('.maincol')).not_to have_content(@admin.display_name)
    expect(page.find('h1')).to have_content @owner.display_name
    expect(page.current_path).to eq user_profile_path(@owner)
  end

  it 'searches the landing page', :guest_enabled, js: true do
    visit landing_page_path
    page.fill_in 'search', with: 'Import'
    page.find('#search').send_keys(:enter)
    sleep(5)
    expect(page.find('.maincol')).to have_content @owner.display_name
    expect(page.find('.maincol')).to have_content @collections.second.title
    expect(page.find('.maincol')).not_to have_content @collections.first.title
  end

  it 'checks guest start transcribing path', :guest_enabled do
    visit collection_start_transcribing_path(@collection.owner, @collection)
    expect(page.current_path).not_to eq dashboard_path
    expect(page).to have_button('Transcribe as guest')
  end
end
