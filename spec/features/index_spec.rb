require "spec_helper"

describe "index page" do
  it "should have a link to log in and sign up if not logged in" do
    visit root_path
    expect(page).not_to have_content("Log out")
    expect(page).to have_content("Log in")
    expect(page).to have_content("Sign Up")
  end

  it "should have link to log out if logged in" do
    visit new_user_session_path
    fill_in "Login", with: "benwbrum"
    fill_in "Password", with: "password"
    click_button "Sign in" do
      expect(page).to have_content("Log out")
      expect(page).not_to have_content("Log in")
      expect(page).not_to have_content("Sign Up")
    end
  end

  it "should not allow invalid logins" do
    visit new_user_session_path
    fill_in "Login",    with: "moemoemoe"
    fill_in "Password", with: "chumba-wumba"
    click_button "Sign in"

    expect(page).to have_content("Invalid user or password.")
    expect(page).not_to have_content("Log out")
    expect(page).to have_content("Log in")
    expect(page).to have_content("Sign Up")
  end
end
