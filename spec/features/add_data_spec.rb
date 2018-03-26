
require 'spec_helper'

describe "uploads data for collections", :order => :defined do

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

  it "starts a new project from tab" do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    select(@collection.title, :from => 'document_upload_collection_id')
    attach_file('document_upload_file', './test_data/uploads/test.pdf')
    click_button('Upload File')
    title = find('h1').text
    expect(title).to eq @collection.title
    expect(page).to have_content("Document has been uploaded")
  end

  it "imports IIIF manifests" do
    #import a manifest for test data
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.fill_in 'at_id', with: "https://data.ucd.ie/api/img/manifests/ivrla:2638"
    find_button('iiif_import').click
    expect(page).to have_content("Metadata")
    expect(page).to have_content("Manifest")
    select(@collection.title, :from => 'sc_manifest_collection_id')
    click_button('Import Manifest')
    expect(page).to have_content(@collection.title)
    visit dashboard_owner_path
    works_count = Work.all.count
    page.find('.tabs').click_link("Start A Project")
    #this manifest has a very long title
    page.fill_in 'at_id', with: "https://data.ucd.ie/api/img/manifests/ivrla:7645"
    find_button('iiif_import').click
    expect(page).to have_content("Metadata")
    expect(page).to have_content("Manifest")
    select(@collection.title, :from => 'sc_manifest_collection_id')
    click_button('Import')
    expect(page).to have_content(@collection.title)
    expect((@collection.works.last.title).length).to be < 255
    new_works = Work.all.count
    expect(new_works).to be > works_count
  
  end

  it "creates an empty work" do
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
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @title).click
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

  it "adds new document sets" do
    @owner = User.find_by(login: OWNER)
    visit dashboard_owner_path
    doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    page.find('.maincol').find('a', text: @set_collection.title).click
    page.find('.tabs').click_link("Settings")
    page.find('.button', text: 'Enable Document Sets').click
    expect(page).to have_content('Create a Document Set')
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: "Test Document Set 1"
    page.find_button('Create Document Set').click
    expect(DocumentSet.last.is_public).to be true
    expect(page.current_path).to eq collection_settings_path(@owner, DocumentSet.last)
    expect(page).to have_content("Manage Works")
    expect(page.find('h1')).to have_content("Test Document Set 1")
    #add a work - has to be done manually b/c it's jquery
    id = @set_collection.works.second.id
    DocumentSet.last.work_ids = id
    DocumentSet.last.save!
    after_doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    expect(after_doc_set).to eq (doc_set + 1)
    visit document_sets_path(:collection_id => @set_collection)
    doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: "Test Document Set 2"
    page.uncheck 'Public'
    page.find_button('Create Document Set').click
    expect(page.current_path).to eq collection_settings_path(@owner, DocumentSet.last)
    expect(page).to have_content("Manage Works")
    expect(page.find('h1')).to have_content("Test Document Set 2")
    expect(DocumentSet.last.is_public).to be false
    after_doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    expect(after_doc_set).to eq (doc_set + 1)
  end

  it "adds works to document sets" do
    @document_sets = DocumentSet.where(owner_user_id: @owner.id)
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @set_collection.title).click
    page.find('.tabs').click_link("Sets")
    expect(page).to have_content("Document Sets for #{@set_collection.title}")
    page.check("work_assignment_#{@document_sets.first.id}_#{@set_collection.works.first.id}")
    page.check("work_assignment_#{@document_sets.last.id}_#{@set_collection.works.last.id}")
    page.find_button('Save').click
  end

end
