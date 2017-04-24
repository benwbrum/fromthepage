require 'spec_helper'

describe "guest user actions" do

  before :all do
    @collections = Collection.all
    @collection = @collections.last
    @work = @collection.works.last
    @page = @work.pages.last
  end

  it "tests guest account creation and migration" do
    visit "/display/display_page?page_id=#{@page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Sign In")
    expect(page).not_to have_content("Signed In As")
    expect(page).to have_button("Transcribe as guest")
    click_button("Transcribe as guest")
    expect(page).to have_content("Signed In As")
    expect(page).to have_button("Save Changes")
    @guest = User.last
    expect(@guest.guest).to be true
    expect(page).to have_link("Sign Up")
    click_link("Sign Up")
    expect(page.current_path).to eq new_user_registration_path

 end

  it "tests guest account transcription" do
    visit "/display/display_page?page_id=#{@page.id}"
    page.find('.tabs').click_link("Transcribe")
    click_button("Transcribe as guest")
    expect(page).to have_content("Signed In As")
    expect(page).to have_button("Save Changes")
    @guest = User.last
    expect(@guest.guest).to be true
    page.fill_in 'page_source_text', with: "Guest Transcription 1"
    click_button('Save Changes')
    expect(page).to have_content("You may save up to three transcriptions as a guest.")
    #check to see what the page versions say
    page.find('.tabs').click_link("Versions")
    expect(page).to have_content("revisions")
    expect(page).to have_link("Guest")
    page.find('.tabs').click_link("Translate")
    page.fill_in 'page_source_translation', with: "Guest Translation"
    click_button('Save Changes')
    expect(page).to have_content("You may save up to three transcriptions as a guest.")
    page.find('.tabs').click_link("Transcribe")
    page.fill_in 'page_source_text', with: "Third Guest Deed"
    click_button('Save Changes')
    #after 3 transcriptions, the user should be forced to sign up
    expect(page.current_path).to eq new_user_registration_path
    fill_in 'Login', with: 'martha'
    fill_in 'Email address', with: 'martha@test.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    fill_in 'Display name', with: 'Martha'
    click_button('Create Account')
    @user = User.last
    expect(@user.login).to eq('martha') 
    expect(@guest.id).to eq(@user.id)
    expect(page.current_path). to eq ("/display/display_page")
    page.find('.tabs').click_link("Versions")
    expect(page).to have_link("Martha")
    expect(page.find('.diff-list')).not_to have_content("Guest")
    
  end

end
