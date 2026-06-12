# frozen_string_literal: true

require 'spec_helper'

describe 'owner actions' do
  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    login_as(owner, scope: :user)
  end

  after do |example|
    if example.metadata[:js]
      owner.all_owner_collections.each(&:destroy!)
      owner.destroy!
    else
      DatabaseCleaner.clean
    end
  end

  let(:owner) { create(:unique_user, :owner, account_type: 'Small Organization') }
  let(:new_collection_title) { "New Test Collection #{SecureRandom.hex(4)}" }
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      subjects_disabled: false,
      works: build_list(:work_with_pages, 2, owner: owner)
    )
  end
  let(:second_collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      works: build_list(:work_with_pages, 2, owner: owner)
    )
  end

  it 'fails to upload a document', js: true do
    collection
    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    page.find(:css, '#document-upload').click
    select2_select(id: 'document_upload_collection_id', value: collection.title)
    click_button('Upload File')
    expect(page).to have_content('prohibited the form from being saved')
    expect(page).to have_content("File can't be blank")
  end

  it 'creates a new collection' do
    collection_count = owner.all_owner_collections.count
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: new_collection_title
    click_button('Create Collection')

    test_collection = Collection.find_by!(title: new_collection_title)
    expect(test_collection.subjects_disabled).to be true
    expect(owner.all_owner_collections.count).to eq(collection_count + 1)
    expect(page).to have_content(test_collection.title)
    expect(page).to have_content('Upload PDF or ZIP File')
  end

  it 'creates an empty new work in a collection', js: true do
    collection
    VCR.use_cassette('sc_collections/gist', record: :none) do
      work_title = "New Test Work #{SecureRandom.hex(4)}"
      visit dashboard_owner_path
      click_link(collection.title)
      click_link('Add a new work')
      expect(page).to have_content(collection.title)
      expect(page).to have_content('Create Empty Work')
      page.find(:css, '#create-empty-work').click
      fill_in 'work_title', with: work_title
      fill_in 'work_description', with: 'This work contains no pages.'
      click_button('Create Work')
      expect(page).to have_content('Here you see the list of all pages in the work.')
      expect(collection.works.find_by(title: work_title)).to be_present
    end
  end

  it 'checks for subjects in a new collection' do
    collection
    visit dashboard_owner_path
    page.find('.maincol').click_link(collection.title)
    page.find('.tabs').click_link('Subjects')
    expect(page).to have_content('Places')
    expect(page).to have_content('People')
  end

  it 'deletes a collection' do
    collection
    collection_count = owner.all_owner_collections.count
    visit dashboard_owner_path
    expect(page.find('.maincol')).to have_content(collection.title)
    page.find('.maincol').click_link(collection.title)
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Danger Zone')
    expect(page).to have_content('Please use caution')
    click_link('Delete Collection')
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).not_to have_content(collection.title)
    expect(owner.all_owner_collections.count).to eq(collection_count - 1)
  end

  it 'creates a collection from work dropdown', js: true do
    collection
    collection_title = "New Work Collection #{SecureRandom.random_number(1_000_000)}"
    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    page.find(:css, '#document-upload', wait: 5).click
    select2_select(id: 'document_upload_collection_id', value: 'Add New Collection')

    within(page.find('.litebox-embed', wait: 5)) do
      expect(page).to have_content('Create New Collection', wait: 5)
      fill_in 'collection_title', with: collection_title
      page.execute_script("$('#create-collection').click()")
    end

    sleep(2)
    page.find(:css, '#document-upload', wait: 5).click

    select_element = find('#document_upload_collection_id', visible: false, wait: 5)
    expect(select_element.value.titleize).to eq(collection_title)
    expect(Collection.find_by(title: collection_title)).to be_present
  end

  it 'creates a subject category' do
    category_count = collection.categories.count
    people_category = collection.categories.find_by!(title: 'People')
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link('Subjects')
    within "#category-#{people_category.id}" do
      click_link('Add Root Category')
    end
    fill_in 'category_title', with: 'New Test Category'
    click_button('Create Category')
    expect(collection.categories.count).to eq(category_count + 1)
    visit collection_subjects_path(collection.owner, collection)
    expect(page).to have_content('New Test Category')
  end

  it 'deletes a subject category' do
    category = create(:category, collection: collection, title: 'New Test Category')
    category_count = collection.categories.count
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link('Subjects')
    expect(page).to have_content(category.title)
    within "#category-#{category.id}" do
      click_link('Delete Category')
    end
    expect(collection.categories.count).to eq(category_count - 1)
    visit collection_subjects_path(collection.owner, collection)
    expect(page).not_to have_content(category.title)
  end

  it 'enables GIS for subject category', js: true do
    category = collection.categories.find_by!(title: 'Places')
    category.update!(gis_enabled: false)
    category_selector = "#category-#{category.id}"

    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link('Subjects')
    expect(page).to have_content('Places')
    page.find('a.tree-item', text: 'Places').click

    page.find(category_selector).find('dl.dropdown.right dt.h5', text: 'Actions', match: :first).click
    page.find(category_selector).find('a', text: 'Enable GIS').click
    expect(page.find('.flash_message')).to have_content('GIS enabled for Places')

    page.find(category_selector).find('dl.dropdown.right dt.h5', text: 'Actions', match: :first).click
    page.find(category_selector).find('a', text: 'Add Child Category').click
    fill_in 'category_title', with: 'Child GIS'
    click_button('Create Category')

    page.find('a.tree-item', text: 'Places').click
    page.find(category_selector).find('dl.dropdown.right dt.h5', text: 'Actions', match: :first).click
    page.find(category_selector).find('a', text: 'Disable GIS').click
    expect(page.find('.flash_message')).to have_content('GIS disabled for Places and 1 child category')

    page.find(category_selector).find('dl.dropdown.right dt.h5', text: 'Actions', match: :first).click
    page.find(category_selector).find('a', text: 'Add Child Category').click
    fill_in 'category_title', with: 'Child GIS-2'
    click_button('Create Category')

    page.find('a.tree-item', text: 'Places').click
    page.find(category_selector).find('dl.dropdown.right dt.h5', text: 'Actions', match: :first).click
    page.find(category_selector).find('a', text: 'Enable GIS').click
    expect(page.find('.flash_message')).to have_content('GIS enabled for Places and 2 child categories')
  end

  it 'fails to create an empty work', js: true do
    second_collection
    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    page.find(:css, '#create-empty-work').click
    select2_select(id: 'work_collection_id', value: second_collection.title)
    fill_in 'work_description', with: 'This work should fail to create.'
    click_button('Create Work')
    expect(page).to have_content('Create Empty Work')
    expect(page).to have_content("Title can't be blank")
  end

  it 'moves a work to another collection', js: true do
    work = create(:work, :with_pages, title: 'This is an empty work', owner: owner, collection: second_collection)
    create(:deed, user: owner, collection: second_collection, work: work, page: work.pages.first)
    collection

    visit dashboard_owner_path
    page.find('.maincol').find('a', text: second_collection.title).click
    page.find('.collection-works').find('a', text: work.title).click
    page.find('.tabs').click_link('Settings')
    expect(page).to have_content(work.title)
    expect(page).to have_content('Work title')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: second_collection.title)
    expect(page.find('#work_collection_id')).to have_content(second_collection.title)
    select(collection.title, from: 'work_collection_id')
    expect(page).to have_content('Work updated successfully')

    work.reload
    expect(work.collection).to eq collection
    expect(work.deeds.where.not(collection_id: collection.id)).to be_empty
    expect(page.find('.breadcrumbs')).to have_selector('a', text: collection.title)
  end

  it "doesn't move a work with articles when confirmation is dismissed", js: true do
    work, test_page = work_with_subject_link
    collection

    visit edit_collection_work_path(second_collection.owner, second_collection, work)
    expect(page).to have_content('Work title')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: second_collection.title)
    message = page.dismiss_confirm do
      select(collection.title, from: 'work_collection_id')
    end
    expect(message).to have_content('Are you sure you want to move this work')
    expect(work.reload.collection).to eq second_collection
    expect(test_page.reload.source_text).to include('[[')
  end

  it 'moves a work with articles when confirmation is accepted', js: true do
    work, test_page = work_with_subject_link
    collection

    visit edit_collection_work_path(second_collection.owner, second_collection, work)
    expect(page).to have_content('Work title')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: second_collection.title)
    accept_confirm do
      select(collection.title, from: 'work_collection_id')
    end
    expect(page).to have_content('Work updated successfully')
    expect(work.reload.collection).to eq collection
    expect(PageArticleLink.where(page_id: work.pages.ids)).to be_empty
    expect(test_page.reload.source_text).not_to include('[[')
  end

  it 'deletes a work', js: true do
    work = create(:work, :with_pages, title: 'This is an empty work', owner: owner, collection: collection)

    visit edit_collection_work_path(collection.owner, collection, work)
    expect(page).to have_content(work.title)
    expect(page).to have_content('Work title')
    click_link('Danger Zone')
    accept_confirm do
      click_link('Delete Work')
    end
    expect(page).to have_content('Work deleted successfully')
    expect(page.current_path).to eq dashboard_owner_path
    page.find('.maincol').find('a', text: collection.title).click
    expect(page).not_to have_content(work.title)
  end

  it 'checks an owner user profile/homepage' do
    document_set = create(:document_set, :public, collection: collection, owner_user_id: owner.id)
    visit dashboard_path
    page.find('a', text: 'Your Profile').click
    expect(page).to have_content(owner.display_name)
    expect(page).to have_selector('.columns')
    expect(page).not_to have_content("Recent Activity by #{owner.display_name}")
    expect(page).to have_content(collection.title)
    expect(page).to have_content(document_set.title)
  end

  it "changes the collection's default language", js: true do
    rtl_collection = create(:collection, owner_user_id: owner.id, text_language: 'eng')
    visit edit_collection_path(owner, rtl_collection)
    page.find('.side-tabs').click_link('Task Configuration')
    first('.select2-container', minimum: 1).click
    find('.select2-dropdown input.select2-search__field').send_keys('Arabic', :enter)
    expect(page).to have_content('Transcription type')
    expect(rtl_collection.reload.text_language).to eq 'ara'
  end

  it 'checks rtl transcription page views' do
    rtl_collection = create(
      :collection,
      owner_user_id: owner.id,
      text_language: 'ara',
      works: build_list(:work_with_pages, 1, owner: owner)
    )
    rtl_page = rtl_collection.pages.first
    visit collection_transcribe_page_path(rtl_collection.owner, rtl_collection, rtl_page.work, rtl_page)
    expect(page.find('.page-editarea')[:dir]).to eq 'rtl'
    page.find('.tabs').click_link('Overview')
    expect(page.find('.page-preview')[:dir]).to eq 'rtl'
  end

  it 'resets the default language' do
    rtl_collection = create(:collection, owner_user_id: owner.id, text_language: 'ara')
    rtl_collection.update!(text_language: 'eng')
    expect(rtl_collection.text_language).to eq 'eng'
  end

  it 'warns if account type is Individual Researcher' do
    owner.update!(account_type: 'Individual Researcher')
    collection
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    expect(owner.collections.count).to be >= 1
    expect(page).to have_content('Individual Researcher Accounts are limited to a single collection.')
  end

  it 'does not warn with another account type' do
    collection
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    expect(page).not_to have_content('Individual Researcher Accounts are limited to a single collection.')
  end

  context 'owner/staff related' do
    let(:owner) do
      create(
        :unique_user,
        :owner,
        login: "wakanda_#{SecureRandom.hex(4)}",
        email: "wakanda_#{SecureRandom.hex(4)}@example.org",
        display_name: 'Wakanda',
        account_type: 'Small Organization'
      )
    end
    let(:staff_user) do
      create(
        :unique_user,
        login: "shuri_#{SecureRandom.hex(4)}",
        email: "shuri_#{SecureRandom.hex(4)}@example.org",
        display_name: 'Shuri'
      )
    end
    let(:letters_title) { "Letters from America #{SecureRandom.hex(4)}" }
    let(:science_title) { "Science Archives #{SecureRandom.hex(4)}" }
    let(:letters_collection) do
      create(:collection, title: letters_title, owner_user_id: owner.id)
    end

    it 'creates a collection as owner' do
      visit dashboard_owner_path
      page.find('a', text: 'Create a Collection').click
      fill_in 'collection_title', with: letters_title
      click_button('Create Collection')
      expect(page).to have_content(letters_title)
    end

    it 'adds a new user as collection owner' do
      letters_collection
      staff_user
      visit dashboard_owner_path
      click_link(letters_title, match: :first)
      click_link('Settings')
      click_link('Privacy & Access')
      page.click_link('Edit Owners')
      select(staff_user.name_with_identifier, from: 'user_id')
      within('.user-select-form') do
        click_button('Add')
      end

      expect(staff_user.reload.owner).to be true
      expect(staff_user.account_type).to eq 'Staff'
      expect(letters_collection.owners).to include(staff_user)
    end

    it "confirms that Shuri can read Wakanda's collection" do
      letters_collection.owners << staff_user
      staff_user.update!(owner: true, account_type: 'Staff')
      logout
      login_as(staff_user, scope: :user)
      visit dashboard_owner_path
      expect(page).to have_content(letters_title)
    end

    it 'creates a collection as Shuri' do
      letters_collection.owners << staff_user
      staff_user.update!(owner: true, account_type: 'Staff')
      logout
      login_as(staff_user, scope: :user)
      visit dashboard_owner_path
      page.find('a', text: 'Create a Collection').click
      fill_in 'collection_title', with: science_title
      click_button('Create Collection')
      expect(page).to have_content(science_title)
      visit dashboard_owner_path
      expect(page).to have_content(letters_title)
      expect(page).to have_content(science_title)
    end

    it 'confirms that Wakanda can read all collections' do
      letters_collection.owners << staff_user
      staff_user.update!(owner: true, account_type: 'Staff')
      create(:collection, title: science_title, owner_user_id: owner.id, owners: [staff_user])
      visit dashboard_owner_path
      expect(page).to have_content(letters_title)
      expect(page).to have_content(science_title)
    end
  end

  def work_with_subject_link
    work = create(:work, owner: owner, collection: second_collection, pages: [])
    test_page = create(:page, work: work)
    test_page.update!(source_text: '[[Switzerland]]')
    article = create(:article, title: 'Switzerland', collection: second_collection)
    create(:page_article_link, page: test_page, article: article, display_text: 'Switzerland')
    [work, test_page]
  end
end
