require 'spec_helper'

describe "Spam user safeguards" do
  it "allows users to modify their profile" do
    user = create(:unique_user)
    login_as(user, scope: :user)
    visit dashboard_watchlist_path
    click_link "Your Profile"
    click_link "Edit Profile"
    fill_in 'Name', with: 'Mary'
    click_button("Update Profile")
    expect(page).to have_content(user.login)
  end

  it "does not present problem fields to non-owners" do
    user = create(:unique_user)
    login_as(user, scope: :user)
    visit dashboard_watchlist_path
    click_link "Your Profile"
    click_link "Edit Profile"
    expect(page).not_to have_content("Website")
    expect(page).not_to have_content("About you")
  end

  it "presents fields to owners" do
    user = create(:unique_user, :owner)
    login_as(user, scope: :user)
    visit dashboard_owner_path
    click_link "Your Profile"
    click_link "Edit Profile"
    expect(page).to have_content("Website")
    expect(page).to have_content("About you")
    fill_in name: 'user[website]', with: "http://www.example.com/"
    fill_in name: 'user[about]', with: "<i>He's just some guy, you know?</i>"
    click_button("Update Profile")
    expect(page).to have_content("just some guy")
    expect(page).to have_content("He's just some guy, you know?")
    # display is only of the word website, not the actual url
    expect(page).to have_content("Website")
  end
end
