require 'spec_helper'

describe "different user role logins" do

  before :all do
    @password = "password"
  end
    
  it "creates a new trial user account" do
    user_count = User.all.count
    visit root_path
    expect(page).to have_link("Sign In")
    first(:link, 'Sign In').click
    expect(page).to have_link("Start Free Trial")
    click_link("Start Free Trial")
    expect(page.current_path).to eq users_new_trial_path
    page.fill_in 'Login', with: 'trial_login'
    page.fill_in 'Email address', with: 'trial_login@test.com'
    page.fill_in 'Password', with: @password
    page.fill_in 'Password confirmation', with: @password
    page.fill_in 'Display name', with: 'trial_login'
    click_button('Create Account')
    expect(page.current_path).to eq dashboard_owner_path
  end
end