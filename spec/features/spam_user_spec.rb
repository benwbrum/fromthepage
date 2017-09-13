require 'spec_helper'

describe "Spam user safeguards " do

  
  
  
  it "allows users to modify their profile" do
    visit "/"
    click_link("Sign Up")
    expect(page.current_path).to eq new_user_registration_path
    fill_in 'Login', with: 'martha'
    fill_in 'Email address', with: 'martha@test.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    fill_in 'Display name', with: 'Martha'
    click_button('Create Account')
    click_link "Your Profile"
    # look for website
    click_link "Edit Profile"
    fill_in 'Name', with: 'Mary'
    expect(page).to have_content("Website")
    click_button("Update Profile")
    expect(page).to have_content("Mary")
  end

  it "does not present problem fields to non-owners"
  it "presents fields to owners"
  it "deletes users who hack problem fields"

  


end