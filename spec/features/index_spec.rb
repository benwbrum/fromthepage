require "spec_helper"

describe "index page" do
  it "should have a link to log in and sign up if not logged in" do
    visit root_path
    page.should_not have_content("Log out")
    page.should have_content("Log in")
    page.should have_content("Sign Up")
  end

  it "should have link to log out if logged in" do
    visit new_user_session_path
    fill_in "Login", with: "benwbrum"
    fill_in "Password", with: "password"
    click_button "Sign in" do
      page.should have_content("Log out")
      page.should_not have_content("Log in")
      page.should_not have_content("Sign Up")
    end
  end

  it "should not allow invalid logins" do
    visit new_user_session_path
    fill_in "Login",    with: "moemoemoe"
    fill_in "Password", with: "chumba-wumba"
    click_button "Sign in"

    page.should have_content("Invalid user or password.")
    page.should_not have_content("Log out")
    page.should have_content("Log in")
    page.should have_content("Sign Up")
  end
end
