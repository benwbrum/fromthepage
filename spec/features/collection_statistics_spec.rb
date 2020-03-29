require 'spec_helper'

describe "collection statistics", :order => :defined do
  before :each do
    @owner = User.where(login: 'carlos').first
    @user = User.where(login: 'jose').first
  end

  it "creates a collection as owner" do
    login_as @owner
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: 'Historia del Paraguay'
    click_button('Create Collection')
    expect(page).to have_content("Historia del Paraguay")
  end

  it "can view the Mailing List Export link as owner" do
    login_as @owner
    c = Collection.where(title: "Historia del Paraguay").first
    visit collection_statistics_path(@owner, c)
    expect(page).to have_content("Mailing List Export")
  end

  it "cannot view the owner's Mailing List Export link as user" do
    logout
    login_as @user
    c = Collection.where(title: "Historia del Paraguay").first
    visit collection_statistics_path(@owner, c)
    expect(page).not_to have_content("Mailing List Export")
  end

  it "adds the user to the owners group" do
    login_as @owner
    visit dashboard_owner_path
    expect(page).to have_content("Historia del Paraguay")
    click_link "Historia del Paraguay", match: :first
    expect(page).to have_content("Settings")
    click_link "Settings"
    select("jose - jose@example.org", from: "user_id").select_option
    within(".user-select-form") do
      click_button "Add"
    end
    @user.reload
    expect(@user.owner).to be(true)
  end

  it "can view the Mailing List Export link as user" do
    logout
    login_as @user
    c = Collection.where(title: "Historia del Paraguay").first
    visit collection_statistics_path(@user, c)
    expect(page).to have_content("Mailing List Export")
  end

  it "does not have a Mailing List Export link for document sets" do
    logout
    login_as @owner
    ds = DocumentSet.first
    visit collection_statistics_path(@owner, ds)
    expect(page).not_to have_content("Mailing List Export")
  end
end
