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

  it "should have access to the Mailing List Export link" do
    login_as @owner
    c = Collection.where(title: "Historia del Paraguay").first
    visit collection_statistics_path(@owner, c)
    expect(page).to have_content("Mailing List Export")
  end

  it "should not have access to the Mailing List Export link" do
    logout
    login_as @user
    c = Collection.where(title: "Historia del Paraguay").first
    visit collection_statistics_path(@owner, c)
    expect(page).not_to have_content("Mailing List Export")
  end
end
