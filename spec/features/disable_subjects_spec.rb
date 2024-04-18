require 'spec_helper'

describe "disable subject linking", :order => :defined do

  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.first
    @work = @collection.works.second
    @title = @work.pages.third.title
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "disables subject indexing in a collection", js: true do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link('Task Configuration')
    expect(page).to have_content("Enable subject indexing")
    uncheck('collection_subjects_enabled')
    #have to find the collection again to make sure it's been updated
    collection = Collection.where(owner_user_id: @owner.id).first
    expect(collection.subjects_disabled).to be true
  end

  it "checks collection level subject items" do
    visit collection_path(@collection.owner, @collection)
    #check for subject related items on Overview tab
    expect(page).to have_content(@collection.title)
    expect(page).to have_content("Works")
    expect(page).not_to have_content("% indexed")
    expect(page).not_to have_content("Subject Categories")
    expect(page.find('.tabs')).not_to have_content("Subjects")
    #check for subject related items on Statistics tab
    page.find('.tabs').click_link("Statistics")
    expect(page).to have_content("Collaborators")
    expect(page).not_to have_content('Subjects')
    expect(page).not_to have_content('References')
    expect(page).not_to have_content('Pages indexed')
    expect(page).not_to have_content('New subjects')
    expect(page).not_to have_content("Indexing")
    #check for subject related items on Export tab
    page.find('.tabs').click_link("Export")
    expect(page).to have_content("Export Individual Works")
    expect(page).not_to have_content("Export Subjects")
    #check for subject related items on Collaborators tab
    page.find('.tabs').click_link("Collaborators")
    expect(page).to have_content("Contributions")
    expect(page).not_to have_content("Recent Subjects")
  end

  it "checks work level subject items" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.tabs').click_link("Help")
    expect(page).to have_content("Transcribing")
    expect(page).not_to have_content("Linking Subjects")
    page.find('.tabs').click_link("Read")
    expect(page).to have_content(@collection.title)
    expect(page).to have_content(@work.title)
    expect(page).not_to have_content("Categories")
    page.find('.tabs').click_link("Contents")
    expect(page).to have_content("Actions")
    expect(page).not_to have_content("Annotate")
  end

  it "checks page level subject items" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    expect(page).not_to have_content("Autolink")
    expect(page).to have_content("A single newline")
    fill_in_editor_field("[[Canonical Subject|display subject]] [[Short Subject]]")
    find('#save_button_top').click
    expect(page).to have_content("[[Canonical Subject|display subject]] [[Short Subject]]")
    expect(page).to have_content("Transcription")
    expect(page).not_to have_selector('a', text: 'display subject')
    expect(page).not_to have_selector('a', text: 'Short Subject')
    page.find('.tabs').click_link("Translate")
    expect(page).not_to have_content("Autolink")
  end

  it "checks export formatting" do
    visit "/export/show?work_id=#{@work.id}"
    expect(page).to have_content("[[Canonical Subject|display subject]] [[Short Subject]]")
    expect(page).not_to have_selector('a', text: 'display subject')
    expect(page).not_to have_selector('a', text: 'Short Subject')
  end

  it "enables subject indexing", js: true do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link('Task Configuration')
    expect(page).to have_content("Enable subject indexing")
    check('collection_subjects_enabled')
    #have to find the collection again to make sure it's been updated
    collection = Collection.where(owner_user_id: @owner.id).first
    expect(collection.subjects_disabled).to be false
  end

 it "checks links work when enabled" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    expect(page).to have_content(@collection.title)
    expect(page).to have_content(@work.title)
    page.find('.work-page_title', text: @title).click_link(@title)
    page.find('.tabs').click_link("Transcribe")
    find('#save_button_top').click

    # Categories
    expect(page).to have_content("Canonical Subject")
    expect(page).to have_content("Short Subject")
    click_link("Continue")

    # Return to read page
    page.find('.tabs').click_link("Overview")
    expect(page).to have_selector('a', text: 'display subject')
    expect(page).to have_selector('a', text: 'Short Subject')
    expect(page).not_to have_content('Canonical Subject')
  end
  it "checks export formatting" do
    visit "/export/show?work_id=#{@work.id}"
    expect(page).to have_selector('a', text: 'display subject')
    expect(page).to have_selector('a', text: 'Short Subject')
  end
end