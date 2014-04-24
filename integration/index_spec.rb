require "spec_helper"

describe "index page" do
  before(:all) do
    # @book = FactoryGirl.create(:book)
    # @book2 = FactoryGirl.create(:book2)
  end

  it "should have a link to log in and sign up if not logged in" do
    visit "/"
    page.should_not have_content("Log out")
    page.should have_content("Log in")
    page.should have_content("Sign Up")
  end

  it "should have link to log out if logged in" do
    p = SessionProvider.get_session
    visit "/"
    page.should have_content("Log out")
    page.should_not have_content("Log in")
    page.should_not have_content("Sign Up")
  end

  it "should not allow invalid logins" do
    user2 = FactoryGirl.create(:user2)
    visit "/account/login"
    fill_in "Login",    :with => "moemoemoe"
    fill_in "Password", :with => "chumba-wumba"
    click_button "Log in"

    # puts "page.body: #{page.body}"
    page.should have_content("Your login and password did not match.")
    page.should_not have_content("Log out")
    page.should have_content("Log in")
    page.should have_content("Sign Up")
  end


end
