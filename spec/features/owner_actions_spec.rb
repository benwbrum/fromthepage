require 'spec_helper'

describe "owner actions", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do

    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.first
    @works = @owner.owner_works
    @title = "This is an empty work"
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "fails to upload a document" do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    select(@collections.first.title, :from => 'document_upload_collection_id')
    click_button('Upload File')
    expect(page).to have_content("prohibited the form from being saved")
    expect(page).to have_content("File can't be blank")
  end

  it "creates a new collection" do
    collection_count = @owner.all_owner_collections.count
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: 'New Test Collection'
    click_button('Create Collection')
    test_collection = Collection.find_by(title: 'New Test Collection')
    expect(collection_count + 1).to eq @owner.all_owner_collections.count
    expect(page).to have_content("#{test_collection.title}")
    expect(page).to have_content("Upload PDF or ZIP File")
  end

  it "creates an empty new work in a collection" do
    test_collection = Collection.find_by(title: 'New Test Collection')
    work_title = "New Test Work"
    visit dashboard_owner_path
    click_link("#{test_collection.title}")
    click_link("Add a new work")
    expect(page).to have_content("#{test_collection.title}")
    expect(page).to have_content("Create Empty Work")
    fill_in 'work_title', with: work_title
    fill_in 'work_description', with: "This work contains no pages."
    click_button('Create Work')
    expect(page).to have_content("Here you see the list of all pages in the work.")
    expect(Work.find_by(title: work_title)).not_to be nil
  end

  it "checks for subject in a new collection" do
    test_collection = Collection.find_by(title: 'New Test Collection')
    visit dashboard_owner_path
    page.find('.maincol').click_link("#{test_collection.title}")
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Places")
    expect(page).to have_content("People")
  end

  it "deletes a collection" do
    test_collection = Collection.find_by(title: 'New Test Collection')
    collection_count = @owner.all_owner_collections.count
    visit dashboard_owner_path
    expect(page.find('.maincol')).to have_content("#{test_collection.title}")
    page.find('.maincol').click_link("#{test_collection.title}")
    page.find('.tabs').click_link("Settings")
    click_link('Delete Collection')
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).not_to have_content("#{test_collection.title}")
    expect(collection_count - 1).to eq @owner.all_owner_collections.count
  end

  it "creates a collection from work dropdown", :js => true do
    col_title = "New Work Collection"
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.select 'Add New Collection', from: 'document_upload_collection_id' 

    within(page.find('.litebox-embed')) do
      expect(page).to have_content('Create New Collection')
      fill_in 'collection_title', with: col_title
      find_button('Create Collection').trigger(:click)
    end
    page.find('#document_upload_collection_id')
    expect(page).to have_select('document_upload_collection_id', selected: col_title)
    sleep(2)
    expect(Collection.last.title).to eq col_title
    #need to remove this collection to prevent conflicts in later tests
    Collection.last.destroy
  end

  it "creates a subject" do
    @count = @collection.categories.count
    cat = @collection.categories.find_by(title: "People")
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Subjects")
    @name = "#category-" + "#{cat.id}"
    page.find(@name).find('a', text: 'Add Root Category').click
    fill_in 'category_title', with: 'New Test Category'
    click_button('Create Category')
    expect(@count + 1).to eq (@collection.categories.count)
    visit "/article/list?collection_id=#{@collection.id}"
    expect(page).to have_content("New Test Category")
  end

  it "deletes a subject" do
    @count = @collection.categories.count
    cat = @collection.categories.find_by(title: "New Test Category")
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("New Test Category")
    @name = "#category-" + "#{cat.id}"
    page.find(@name).find('a', text: 'Delete Category').click
    expect(@count - 1).to eq (@collection.categories.count)
    visit "/article/list?collection_id=#{@collection.id}"
    expect(page).not_to have_content("New Test Category")
  end

  it "fails to create an empty work" do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    select(@collections.last.title, :from => 'work_collection_id')
    fill_in 'work_description', with: "This work should fail to create."
    click_button('Create Work')
    expect(page).to have_content("Create Empty Work")
    expect(page).to have_content("Title can't be blank")
  end

  it "moves a work to another collection" do
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @title).click
    expect(page).to have_content(@title)
    expect(page).to have_content("Work title")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @collections.second.title)
    expect(page.find('#work_collection_id')).to have_content(@collections.second.title)
    select(@collection.title, :from => 'work_collection_id')
    click_button('Save Changes')
    expect(page).to have_content("Work updated successfully")
    expect(Deed.last.work_id).to eq (Work.find_by(title: @title).id)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @collection.title)
  end

  it "doesn't move a work with articles", :js => true do
    col = Collection.second
    work = col.works.second
    test_page = work.pages.first
    visit collection_transcribe_page_path(col.owner, col, work, test_page)
    page.fill_in 'page_source_text', with: "[[Switzerland]]"
    click_button('Save Changes')
    expect(page.find('.flash_message')).to have_content("Saved")
    visit edit_collection_work_path(col.owner, col, work)
    expect(page).to have_content("Work title")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: col.title)
    select(@collection.title, :from => 'work_collection_id')
    #reject the modal and get text
    message = page.dismiss_confirm do
      click_button('Save Changes')
    end
    expect(message).to have_content("Are you sure you want to move this work")
    expect(Work.find_by(id: work.id).collection).to eq col
  end

  it "moves a work with articles" do
    col = Collection.second
    work = col.works.second
    test_page = work.pages.first
    #note: this is probably redundant, but it prevents failure from other tests
    visit collection_transcribe_page_path(col.owner, col, work, test_page)
    page.fill_in 'page_source_text', with: "[[Switzerland]]"
    click_button('Save Changes')
    expect(page.find('.flash_message')).to have_content("Saved")
    visit edit_collection_work_path(col.owner, col, work)
    expect(page).to have_content("Work title")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: col.title)
    select(@collection.title, :from => 'work_collection_id')
    click_button('Save Changes')
    #the modal is silently accepted by default
    expect(Work.find_by(id: work.id).collection).not_to eq col
    expect(Work.find_by(id: work.id).collection).to eq @collection
    #check the links
    expect(PageArticleLink.where(page_id: work.pages.ids)).to be_empty
    test_page2 = Page.find_by(id: test_page.id)
    expect(test_page2.source_text).not_to have_content('[[')
  end

  it "deletes a work" do
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @title).click
    expect(page).to have_content(@title)
    expect(page).to have_content("Work title")
    click_link("Delete Work")
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).not_to have_content(@title)
  end

  it "checks an owner user profile/homepage" do
    visit dashboard_path
    page.find('a', text: 'Your Profile').click
    expect(page).to have_content(@owner.display_name)
    expect(page).to have_selector('.columns')
    expect(page.find('.maincol')).to have_content("Collections")
    expect(page).not_to have_content("Recent Activity by #{@owner.display_name}")
    @collections.each do |c|
        expect(page).to have_content(c.title)
    end
    @owner.unrestricted_document_sets.each do |d|
      expect(page).to have_content(d.title)
    end
  end

end
