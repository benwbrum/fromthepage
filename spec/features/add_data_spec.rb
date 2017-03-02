
require 'spec_helper'

describe "uploads data for collections", :order => :defined do

  before :all do

    @user = User.find_by(login: 'margaret')
    @collections = @user.all_owner_collections
    @collection = @collections.second
    @title = "This is an empty work"
  end

  it "starts a new project from tab" do
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    select(@collection.title, :from => 'document_upload_collection_id')
    attach_file('document_upload_file', './test_data/uploads/test.pdf')
    click_button('Upload File')
    title = find('h1').text
    expect(title).to eq @collection.title
    expect(page).to have_content("Document has been uploaded")
  end
  #note: this test depends on the code from iiif-import
=begin
  it "imports a IIIF manifest" do
    login_as(@user, :scope => :user)
    works_count = Work.all.count
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.fill_in 'at_id', with: "https://data.ucd.ie/api/img/manifests/duchas:5141774"
    click_button('Import')
    expect(page).to have_content("Metadata")
    click_link('Import')
    expect(page).to have_content("Import Manifest")
    select(@collection.title, :from => 'sc_manifest_collection_id')
    click_button('Import')
    expect(page).to have_content(@collection.title)
    new_works = Work.all.count
    expect(new_works).to eq (works_count + 1)

  end
=end
  it "creates an empty work" do
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    select(@collection.title, :from => 'work_collection_id')
    fill_in 'work_title', with: @title
    fill_in 'work_description', with: "This work contains no pages."
    click_button('Create Work')
    expect(page).to have_content("Here you see the list of all pages in the work.")
    expect(Work.find_by(title: @title)).not_to be nil
  end

  it "adds pages to an empty work" do
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('a', text: @title).click
    page.find('.tabs').click_link("Pages")
    page.find('a', text: "Add New Page").click
    attach_file('page_base_image', './test_data/uploads/JWGravesAmnestyPage1.jpg')
    click_button('Save & Add Next Page')
    work = Work.find_by(title: @title)
    pages = work.pages
    expect(pages).not_to be nil
    expect(page).to have_content(pages.first.title)
    page.find('a', text: "Add New Page").click
    attach_file('page_base_image', './test_data/uploads/JWGravesAmnestyPage2.jpg')
    click_button('Save & New Work')
    count = work.pages.count
    expect(count).to eq 2
    expect(page).to have_content("Create Empty Work")
    #testing the cancel button involves ajax
  end

  it "checks that the file has been uploaded" do
    sleep(60)
    @work = Work.find_by(title: 'test')
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_content(@work.title)
    expect(page).to have_content(@work.pages.first.title)
    click_link(@work.pages.first.title)
    expect(page).to have_content('This page is not transcribed')
  end

end
