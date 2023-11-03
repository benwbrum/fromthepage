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

  it "starts a new project from tab and then enable its forum and access forum", :js => true do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.find(:css, "#document-upload").click
    select(@collection.title, :from => 'document_upload_collection_id')

    # workaround
    script = "$('#document_upload_file').css({opacity: 100, display: 'block', position: 'relative', left: ''});"
    page.execute_script(script)

    attach_file('document_upload_file', './test_data/uploads/test.pdf')
    click_button('Upload File')
    title = find('h1').text
    expect(title).to eq @collection.title
    expect(page).to have_content("Document has been uploaded")
    wait_for_upload_processing
    sleep(10)
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