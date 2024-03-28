require 'spec_helper'

describe "owner actions", :order => :defined do
  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.first
    @works = @owner.owner_works
    @title = "This is an empty work"
    @rtl_collection = Collection.find(3)
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "fails to upload a document", :js => true do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.find(:css, "#document-upload").click
    select(@collections.first.title, :from => 'document_upload_collection_id')
    click_button('Upload File')
    expect(page).to have_content("prohibited the form from being saved")
    expect(page).to have_content("File can't be blank")
  end

  it "creates a new collection" do
    @owner.account_type = "Small Organization"
    collection_count = @owner.all_owner_collections.count
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: 'New Test Collection'
    click_button('Create Collection')
    test_collection = Collection.find_by(title: 'New Test Collection')
    expect(test_collection.subjects_disabled).to be true
    expect(collection_count + 1).to eq @owner.all_owner_collections.count
    expect(page).to have_content("#{test_collection.title}")
    expect(page).to have_content("Upload PDF or ZIP File")
  end

  it "creates an empty new work in a collection", :js => true do
    @owner.account_type = "Small Organization"
    test_collection = Collection.find_by(title: 'New Test Collection')
    work_title = "New Test Work"
    visit dashboard_owner_path
    click_link("#{test_collection.title}")
    click_link("Add a new work")
    expect(page).to have_content("#{test_collection.title}")
    expect(page).to have_content("Create Empty Work")
    page.find(:css, "#create-empty-work").click
    fill_in 'work_title', with: work_title
    fill_in 'work_description', with: "This work contains no pages."
    click_button('Create Work')
    expect(page).to have_content("Here you see the list of all pages in the work.")
    expect(Work.find_by(title: work_title)).not_to be nil
  end

  it "checks for subject in a new collection" do
    @owner.account_type = "Small Organization"
    test_collection = Collection.find_by(title: 'New Test Collection')
    test_collection.subjects_disabled = false
    test_collection.save
    visit dashboard_owner_path
    page.find('.maincol').click_link("#{test_collection.title}")
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Places")
    expect(page).to have_content("People")
  end

  it "deletes a collection" do
    @owner.account_type = "Small Organization"
    test_collection = Collection.find_by(title: 'New Test Collection')
    collection_count = @owner.all_owner_collections.count
    visit dashboard_owner_path
    expect(page.find('.maincol')).to have_content("#{test_collection.title}")
    page.find('.maincol').click_link("#{test_collection.title}")
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Danger Zone")
    expect(page).to have_content("Please use caution")
    click_link('Delete Collection')
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).not_to have_content("#{test_collection.title}")
    expect(collection_count - 1).to eq @owner.all_owner_collections.count
  end

  it "creates a collection from work dropdown", :js => true do
    @owner.account_type = "Small Organization"
    col_title = "New Work Collection"
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.find(:css, '#document-upload').click
    page.select 'Add New Collection', from: 'document_upload_collection_id' 

    within(page.find('.litebox-embed')) do
      expect(page).to have_content('Create New Collection')
      fill_in 'collection_title', with: col_title
      page.execute_script("$('#create-collection').click()")
    end
    sleep(2)
    page.execute_script("$('#document-upload').click()")
    page.find('#document_upload_collection_id')
    expect(page).to have_select('document_upload_collection_id', selected: col_title)
    sleep(2)
    expect(Collection.last.title).to eq col_title
    #need to remove this collection to prevent conflicts in later tests
    Collection.last.destroy
  end

  it "creates a subject category" do
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

  it "deletes a subject category" do
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

  it "enables GIS for subject category" do
    category = @collection.categories.find_by(title: "Places")
    category.gis_enabled = false
    category.save

    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Subjects")
    @name = "#category-" + "#{category.id}"
    page.find(@name).find('a', text: 'Enable GIS').click
    expect(page.find('.flash_message')).to have_content("GIS enabled for Places")
    page.find(@name).find('a', text: 'Add Child Category').click
    fill_in 'category_title', with: 'Child GIS'
    click_button('Create Category')
    page.find(@name).find('a', text: 'Disable GIS').click
    expect(page.find('.flash_message')).to have_content("GIS disabled for Places and 1 child category")
    page.find(@name).find('a', text: 'Add Child Category').click
    fill_in 'category_title', with: 'Child GIS-2'
    click_button('Create Category')
    page.find(@name).find('a', text: 'Enable GIS').click
    expect(page.find('.flash_message')).to have_content("GIS enabled for Places and 2 child categories")
  end

  it "fails to create an empty work", :js => true do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.find(:css, "#create-empty-work").click
    select(@collections.last.title, :from => 'work_collection_id')
    fill_in 'work_description', with: "This work should fail to create."
    click_button('Create Work')
    expect(page).to have_content("Create Empty Work")
    expect(page).to have_content("Title can't be blank")
  end

  it "moves a work to another collection" do
    work = Work.find_by(title: @title)

    visit dashboard_owner_path
    page.find('.maincol').find('a', text: work.collection.title).click
    page.find('.collection-works').find('a', text: @title).click
    page.find('.tabs').click_link('Settings')
    expect(page).to have_content(@title)
    expect(page).to have_content("Work title")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @collections.second.title)
    expect(page.find('#work_collection_id')).to have_content(@collections.second.title)
    select(@collection.title, :from => 'work_collection_id')
    click_button('Save Changes')
    expect(page).to have_content("Work updated successfully")
    work = Work.find_by(title: @title)
    expect(Deed.last.work_id).to eq(work.id)
    expect(work.deeds.where.not(:collection_id => work.collection_id).count).to eq(0)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @collection.title)
  end

  it "doesn't move a work with articles", :js => true do
    col = Collection.second
    work = col.works.second
    test_page = work.pages.first

    visit collection_transcribe_page_path(col.owner, col, work, test_page)
    fill_in_editor_field "[[Switzerland]]"
    find('#save_button_top').click
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
    fill_in_editor_field "[[Switzerland]]"
    find('#save_button_top').click
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
    collection = Work.find_by(title: @title).collection

    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @collection.title).click
    page.find('.collection-works').find('a', text: @title).click
    page.find('.tabs').click_link('Settings')
    expect(page).to have_content(@title)
    expect(page).to have_content("Work title")
    click_link("Delete Work")
    expect(page.current_path).to eq dashboard_owner_path
    page.find('.maincol').find('a', text: collection.title).click
    expect(page).not_to have_content(@title)
  end

  it "checks an owner user profile/homepage" do
    visit dashboard_path
    page.find('a', text: 'Your Profile').click
    expect(page).to have_content(@owner.display_name)
    expect(page).to have_selector('.columns')
    expect(page).not_to have_content("Recent Activity by #{@owner.display_name}")
    @collections.each do |c|
      expect(page).to have_content(c.title)
    end
    @owner.unrestricted_document_sets.each do |d|
      expect(page).to have_content(d.title)
    end
  end

  it "changes the collection's default language", js: true do
    visit edit_collection_path(@owner, @rtl_collection)
    page.find('.side-tabs').click_link("Task Configuration")
    first('.select2-container', minimum: 1).click
    find('.select2-dropdown input.select2-search__field').send_keys("Arabic", :enter)
    expect(page).to have_content('Transcription type')
    expect(Collection.find(3).text_language).to eq 'ara'
  end

  it "checks rtl transcription page views" do
    rtl_page = @rtl_collection.works.first.pages.first
    visit collection_transcribe_page_path(@rtl_collection.owner, @rtl_collection, rtl_page.work, rtl_page)
    #check transcription page direction
    expect(page.find('.page-editarea')[:dir]).to eq 'rtl'
    #check overview page direction
    page.find('.tabs').click_link('Overview')
    expect(page.find('.page-preview')[:dir]).to eq 'rtl'
  end

  it "resets the default language" do
    rtl_collection = Collection.last
    rtl_collection.text_language = "eng"
    rtl_collection.save!
    expect(rtl_collection.text_language).to eq 'eng'
  end

  it "warns if account type is Individual Researcher" do
    @owner.account_type = "Individual Researcher"
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    expect(@owner.collections.count).to be >= 1
    expect(page).to have_content("Individual Researcher Accounts are limited to a single collection.")
  end

  it "does not warn with another account type" do
    @owner.account_type = "Small Organization"
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    expect(page).not_to have_content("Individual Researcher Accounts are limited to a single collection.")
  end

  context "owner/staff related" do
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
      click_link "Privacy & Access"
      page.click_link 'Edit Owners'
      select("shuri - shuri@example.org", from: "user_id").select_option
      within(".user-select-form") do
        click_button "Add"
      end
      @user.reload
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
end
