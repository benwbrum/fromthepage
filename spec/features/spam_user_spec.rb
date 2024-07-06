require 'spec_helper'

describe "Spam user safeguards" do

  it "allows users to modify their profile" do
    user = create('martha1')
    click_link "Your Profile"
    # look for website
    click_link "Edit Profile"
    fill_in 'Name', with: 'Mary'
    click_button("Update Profile")
    expect(page).to have_content("martha1")
  end

  it "does not present problem fields to non-owners" do
    user = create('martha2')
    click_link "Your Profile"
    # look for website
    click_link "Edit Profile"
    expect(page).not_to have_content("Website")
    expect(page).not_to have_content("About you")
  end

  it "presents fields to owners" do
    user = create('martha3')
    user.owner = true
    user.save!

    click_link "Your Profile"
    # look for website
    click_link "Edit Profile"
    expect(page).to have_content("Website")
    expect(page).to have_content("About you")
    fill_in name: 'user[website]', with: "http://www.example.com/"
    fill_in name: 'user[about]', with: "<i>He's just some guy, you know?</i>"
    click_button("Update Profile")
    expect(page).to have_content("just some guy")
    expect(page).to have_content("He's just some guy, you know?")
    #display is only of the word website, not the actual url
    expect(page).to have_content("Website")
  end



  def create(login)
    visit "/"
    first(:link, 'Sign In').click
    click_link("Sign Up Now")
    expect(page.current_path).to eq new_user_registration_path
    fill_in 'Username', with: login
    fill_in 'Email Address', with: "#{login}@test.com"
    fill_in 'Password', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    fill_in 'Real Name', with: 'Martha'
    click_button('Create Account')

    user = User.where(:login => login).first
    user
  end




end
