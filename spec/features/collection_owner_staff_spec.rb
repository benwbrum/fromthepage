require 'spec_helper'

describe "collection owner/staff specs" do
  before :each do
    @owner = User.where(login: 'wakanda').first
    @user = User.where(login: 'shuri').first
  end

  it "creates a collection as owner" do
    login_as @owner
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: 'Letters from America'
    click_button('Create Collection')
    expect(page).to have_content("Letters from America")
  end

  it "adds a new user as collection owner" do
    login_as @owner
    visit dashboard_owner_path
    expect(page).to have_content("Letters from America")
    click_link "Letters from America", match: :first
    expect(page).to have_content("Settings")
    click_link "Settings"
    select("Shuri - shuri@example.org", from: "user_id").select_option
    within(".user-select-form") do
      click_button "Add"
    end
    expect(@user.owner).to be(true)
    expect(@user.account_type).to eq "Staff"
  end

  it "confirms that Shuri can read Wakanda's collection" do
    logout
    login_as @user
    visit dashboard_owner_path
    expect(page).to have_content("Letters from America")
  end

  it "creates a collection as Shuri" do
    login_as @user
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: 'Science Archives'
    click_button('Create Collection')
    expect(page).to have_content("Science Archives")
    visit dashboard_owner_path
    expect(page).to have_content("Letters from America")
    expect(page).to have_content("Science Archives")
  end

  it "confirms that Wakanda can read all collections" do
    logout
    login_as @owner
    visit dashboard_owner_path
    expect(page).to have_content("Letters from America")
    expect(page).to have_content("Science Archives")
  end
end
