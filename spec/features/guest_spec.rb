# frozen_string_literal: true

require 'spec_helper'

describe 'guest user actions' do
  GUEST_NAV_HEADING = 'Create An Account'

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    stub_const('GUEST_TRANSCRIPTION_ENABLED', true) if example.metadata[:guest_enabled]
  end

  after do |example|
    if example.metadata[:js]
      owner.all_owner_collections.each do |owned_collection|
        owned_collection.categories.destroy_all
        owned_collection.destroy!
      end
      owner.destroy!
    else
      DatabaseCleaner.clean
    end
  end

  let(:owner) do
    create(
      :unique_user,
      :owner,
      account_type: 'Small Organization',
      display_name: 'Guest Test Organization'
    )
  end
  let(:admin) { create(:unique_user, :admin, display_name: 'Guest Test Administrator') }
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      works: [],
      title: 'Guest Transcription Collection'
    )
  end
  let(:work) { create(:work, collection: collection, owner: owner) }
  let(:work_page) { create(:page, work: work) }

  it 'returns 403 from the guest transcription route by default' do
    page.driver.post("/application/guest_transcription?page_id=#{work_page.id}")

    expect(page.status_code).to eq(403)
  end

  it 'does not show transcribe as guest by default' do
    open_guest_transcription

    expect(page).to have_button('Sign Up Now')
    expect(page).not_to have_button('Transcribe as guest')
  end

  it 'shows transcribe as guest when enabled', :guest_enabled do
    open_guest_transcription

    expect(page).to have_button('Transcribe as guest')
  end

  it 'creates a guest account and opens registration', :guest_enabled do
    open_guest_transcription

    expect(page).to have_selector('span', text: 'Sign In')
    expect(page).not_to have_content('Signed In As')
    expect(page).not_to have_content(GUEST_NAV_HEADING)
    click_button('Transcribe as guest')

    expect(page).to have_button('Save')
    expect(page).to have_content('Guest')
    expect(page).to have_link(GUEST_NAV_HEADING)

    guest = User.find_by!(guest: true)
    expect(guest).to be_guest

    first(:link, GUEST_NAV_HEADING).click
    expect(page).to have_content('Sign Up')
  end

  it 'migrates guest transcriptions to a registered account', :guest_enabled do
    open_guest_transcription
    expect(page).to have_content('Sign In')
    click_button('Transcribe as guest')

    expect(page).to have_content(GUEST_NAV_HEADING)
    expect(page).to have_button('Save')
    guest = User.find_by!(guest: true)

    fill_in_editor_field 'Guest Transcription 1'
    find('#save_button_top').click
    expect(page).to have_content("You may save up to #{GUEST_DEED_COUNT} transcriptions as a guest.")

    page.find('.tabs').click_link('Versions')
    expect(page).to have_content('revisions')
    expect(page).to have_link('Guest')

    page.find('.tabs').click_link('Transcribe')
    fill_in_editor_field 'Second Guest Deed'
    find('#save_button_top').click
    fill_in_editor_field 'Third Guest Deed'
    find('#save_button_top').click

    expect(page.current_path).to eq(new_user_registration_path)
    registration_login = "guest-convert-#{SecureRandom.hex(4)}"
    fill_in 'Username', with: registration_login
    fill_in 'Email Address', with: "#{registration_login}@test.com"
    fill_in 'Password', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    fill_in 'Real Name', with: 'Martha'
    click_button('Create Account')

    registered_user = User.find(guest.id)
    expect(registered_user.login).to eq(registration_login)
    expect(registered_user).not_to be_guest
    expect(page.current_path).to eq(collection_transcribe_page_path(owner, collection, work, work_page))

    expect(page.find('.tabs')).to have_link('Versions')
    page.find('.tabs').click_link('Versions')
    expect(page).to have_link(registration_login)
  end

  it 'looks at the landing page', :guest_enabled do
    collection
    admin
    visit landing_page_path

    expect(page.find('.maincol')).to have_link(owner.display_name)
    page.find('.maincol').first('a', text: owner.display_name).click
    expect(page.find('.maincol')).not_to have_content(admin.display_name)
    expect(page.find('h1')).to have_content(owner.display_name)
    expect(page.current_path).to eq(user_profile_path(owner))
  end

  it 'searches the landing page', :guest_enabled, js: true do
    matching_collection = collection
    other_collection = create(
      :collection,
      owner_user_id: owner.id,
      works: [],
      title: 'Unrelated Guest Collection'
    )

    visit landing_page_path
    page.fill_in 'search', with: 'Guest Transcription'
    page.find('#search').send_keys(:enter)

    expect(page.find('.maincol')).to have_content(owner.display_name)
    expect(page.find('.maincol')).to have_content(matching_collection.title)
    expect(page.find('.maincol')).not_to have_content(other_collection.title)
  end

  it 'starts guest transcription from a collection', :guest_enabled do
    work_page
    visit collection_start_transcribing_path(owner, collection)

    expect(page.current_path).not_to eq(dashboard_path)
    expect(page).to have_button('Transcribe as guest')
  end

  def open_guest_transcription
    visit collection_display_page_path(owner, collection, work, work_page)
    page.find('.tabs').click_link('Transcribe')
  end
end
