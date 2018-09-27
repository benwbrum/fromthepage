require 'spec_helper'

describe "guest user actions" do
  let(:owner) { User.find_by(login: OWNER) }
  let(:admin) { User.find_by(login: ADMIN) }
  let(:guest_user) { User.last }

  let(:all_collections) { Collection.all }
  let(:collection) { Collection.last }
  let(:work) { collection.works.last }
  # 'page' is a protected word in Capybara, so our instance of
  # the 'Page' class is called 'page1' to avoid collision.
  let(:page1) { work.pages.last }

  it "tests guest account creation and migration" do
    visit "/display/display_page?page_id=#{page1.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Sign In")
    expect(page).not_to have_content("Signed In As")
    expect(page).to have_button("Transcribe as guest")
    click_button("Transcribe as guest")
    expect(page).to have_content("Signed In As")
    expect(page).to have_button("Save Changes")
    expect(guest_user.guest).to be true
    # Guests get to save n many changes before an account is required:
    GUEST_DEED_COUNT.times do
      click_button("Save Changes")
      sleep(3)
    end
    expect(page.current_path).to eq new_user_registration_path
    find_link("Sign in existing account", href: "/users/sign_in").click
    expect(page.current_path).to eq new_user_session_path
 end

  xit "tests guest account transcription" do
    visit collection_display_page_path(collection.owner, collection, work, page1.id)
    page.find('.tabs').click_link("Transcribe")
    click_button("Transcribe as guest")
    expect(page).to have_content("Signed In As")
    expect(guest_user.guest).to be true
    expect(page).to have_button("Save Changes")
    page.fill_in 'page_source_text', with: "Guest Transcription 1"
    click_button('Save Changes')
    expect(page).to have_content("You may save up to #{GUEST_DEED_COUNT} transcriptions as a guest.")

    # Check to see Guest user is listed in the Versions
    page.find('.tabs').click_link("Versions")
    expect(page).to have_content("revisions")
    expect(page).to have_link("Guest")

    # Guest adds a translation
    page.find('.tabs').click_link("Translate")
    page.fill_in 'page_source_translation', with: "Guest Translation"
    click_button('Save Changes')
    expect(page).to have_content("You may save up to #{GUEST_DEED_COUNT} transcriptions as a guest.")

    page.find('.tabs').click_link("Transcribe")
    page.fill_in 'page_source_text', with: "Third Guest Deed"
    click_button('Save Changes')

    # After 3 transcriptions, the user should be forced to sign up
    expect(page.current_path).to eq new_user_registration_path
    fill_in 'Login', with: 'martha'
    fill_in 'Email address', with: 'martha@test.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    fill_in 'Display name', with: 'Martha'

    click_button('Create Account')
    user = User.find_by(login: 'martha')
    # expect(guest_user.id).to eq(user.id)
    expect(page.current_path). to eq collection_transcribe_page_path(collection.owner, collection, work, page1.id)
    page.find('.tabs').click_link("Versions")
    expect(page).to have_link("Martha")
    expect(page.find('.diff-list')).not_to have_content("Guest")
  end

  it "looks at the landing page" do
    visit landing_page_path
    expect(page).to have_selector('.carousel')
    expect(page.find('.maincol')).to have_link(owner.display_name)
    page.find('.maincol').click_link(owner.display_name)
    expect(page).to have_content("Recent Activity")
    expect(page.find('.maincol')).not_to have_content(admin.display_name)
    expect(page.find('h1')).to have_content owner.display_name
    expect(page.current_path).to eq user_profile_path(owner)
  end

  it "searches the landing page" do
    visit landing_page_path
    page.fill_in 'search', with: 'Import'
    click_button('Search')
    expect(page).not_to have_selector('.carousel')
    expect(page.find('.maincol')).to have_content owner.display_name
    expect(page.find('.maincol')).to have_content all_collections.second.title
    expect(page.find('.maincol')).not_to have_content all_collections.first.title
  end

  it "checks guest start transcribing path" do
    visit collection_start_transcribing_path(collection.owner, collection)
    expect(page.current_path).not_to eq dashboard_path
    expect(page).to have_button("Transcribe as guest")
  end

end
