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

  it "starts a new project from tab", :js => true do
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
  end

  it "starts an ocr project", :js => true do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.find(:css, "#document-upload").click
    select(@collection.title, :from => 'document_upload_collection_id')

    # workaround
    script = "$('#document_upload_file').css({opacity: 100, display: 'block', position: 'relative', left: ''});"
    page.execute_script(script)

    attach_file('document_upload_file', './test_data/uploads/ocr.pdf')
    page.check('Import text from PDF text layers, text files or XML files.')
    click_button('Upload File')
    title = find('h1').text
    expect(title).to eq @collection.title
    expect(page).to have_content("Document has been uploaded")
    wait_for_upload_processing
    uploaded_work = Work.last
    expect(uploaded_work.ocr_correction).to eq true
    expect(uploaded_work.pages.first.source_text).to match 'dagegen'
  end

  it "imports IIIF manifests", :js => true do
    #import a manifest for test data
    VCR.use_cassette('iiif/imports_iiif_manifests', :record => :new_episodes) do
      visit dashboard_owner_path
      page.find('.tabs').click_link("Start A Project")
      page.find(:css, "#import-iiif-manifest").click
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
      page.find(:css, "#import-iiif-manifest").click
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
      expect(new_works).to be >= works_count
    end
  end

  it "creates an empty work", :js => true do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.find(:css, "#create-empty-work").click
    select(@collection.title, :from => 'work_collection_id')
    fill_in 'work_title', with: @title
    fill_in 'work_description', with: "This work contains no pages."
    click_button('Create Work')
    expect(page).to have_content("Here you see the list of all pages in the work.")
    expect(Work.find_by(title: @title)).not_to be nil
  end

  it "adds pages to an empty work" do
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @collection.title).click
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
    work = Work.find(work.id)
    expect(work.work_statistic[:total_pages]).to eq 2
    expect(page).to have_content("Create Empty Work")
    #testing the cancel button involves ajax
  end

  it "adds new document sets", js: true do
    @owner = User.find_by(login: OWNER)
    visit dashboard_owner_path
    doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    page.find('.maincol').find('a', text: @set_collection.title).click
    page.find('.tabs').click_link("Settings")
    sleep 1
    page.find('.side-tabs').click_link("Look & Feel")
    page.check('Enable document sets')
    page.click_link('Edit Sets')
    expect(page).to have_content('Create a Document Set')
    page.find('.button', text: 'Create a Document Set').click
    sleep(1)
    page.fill_in 'document_set_title', with: "Test Document Set 1"
    page.find_button('Create Document Set').click
    sleep(3)
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
    sleep(3)
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
    page.check("work_assignment_#{@set_collection.works.first.slug}_#{@document_sets.first.slug}")
    page.check("work_assignment_#{@set_collection.works.last.slug}_#{@document_sets.last.slug}")
    page.find_button('Save').click
  end
end