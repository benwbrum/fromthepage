require 'spec_helper'

describe "forum tab for collection", :order => :defined do
  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
    @set_collection = @collections.last
    @title = "This is an empty work"
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "sets slugs" do
    Collection.find_each(&:save)
    Work.find_each(&:save)
    User.find_each(&:save)
  end

  it "visits a collection then enables its forum and access forum", :js => true do
    visit collection_path(@collection.owner, @collection)
    # Goto settings tab enable forums and then visit forums tab
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link('Look & Feel')
    page.check('Enable forums')
    sleep(1)
    visit current_path # reload page to get the new forum tab
    page.find('.tabs').click_link("Forum")
    expect(page).to have_content("All Messageboards")
    expect(page).to have_content("Create a New Messageboard")

    # Goto settings tab again and disable it
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link('Look & Feel')
    page.uncheck('Enable forums')
    sleep(1)
    visit current_path 
    expect(page.find('.tabs')).to_not have_content("Forum")
  end

end