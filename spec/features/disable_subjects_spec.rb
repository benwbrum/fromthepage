require 'spec_helper'

describe "disable subject linking", :order => :defined do

  before :all do
    @user = User.find_by(login: 'margaret')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @work = @collection.works.second
  end

  it "disables subject indexing in a collection" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content("Disable subject indexing")
    check('collection_subjects_disabled')
    click_button('Save Changes')
    #have to find the collection again to make sure it's been updated
    collection = Collection.where(owner_user_id: @user.id).first
    expect(collection.subjects_disabled).to be true
  end

  it "checks collection level subject items" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    #check for subject related items on Overview tab
    expect(page).to have_content(@collection.title)
    expect(page).to have_content("Works")
    expect(page).not_to have_content("% indexed")
    expect(page).not_to have_content("Subject Categories")
    expect(page.find('.tabs')).not_to have_content("Subjects")
    #check for subject related items on Statistics tab
    page.find('.tabs').click_link("Statistics")
    expect(page).to have_content("Work Progress")
    expect(page).not_to have_content('Subjects')
    expect(page).not_to have_content('References')
    expect(page).not_to have_content('Pages indexed')
    expect(page).not_to have_content('New subjects')
    expect(page).not_to have_content("% indexed")
    expect(page).not_to have_content("Indexing")
    #check for subject related items on Export tab
    page.find('.tabs').click_link("Export")
    expect(page).to have_content("Export Individual Works")
    expect(page).not_to have_content("Export Subject Index")
    #check for subject related items on Collaborators tab
    page.find('.tabs').click_link("Collaborators")
    expect(page).to have_content("Contributions")
    expect(page).not_to have_content("Recent Subjects")
  end

  it "checks work and page level subject items" do
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@work.id}"
    page.find('.tabs').click_link("Help")
    expect(page).to have_content("Transcribing")
    expect(page).not_to have_content("Linking Subjects")
    page.find('.tabs').click_link("Read")
    expect(page).to have_content(@collection.title)
    expect(page).to have_content(@work.title)
    expect(page).not_to have_content("Categories")
    click_link @work.pages.first.title
    expect(page).to have_content("Transcription")
    page.find('.tabs').click_link("Transcribe")
    expect(page).not_to have_content("Autolink")
    expect(page).to have_content("A single newline")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button("Save Changes")
    expect(page).to have_content("Texas")
    expect(page).to have_content("Transcription")
    expect(page).not_to have_selector('a', text: 'Texas')
    page.find('.tabs').click_link("Translate")
    expect(page).not_to have_content("Autolink")

  end

  it "enables subject indexing" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content("Disable subject indexing")
    uncheck('collection_subjects_disabled')
    click_button('Save Changes')
    #have to find the collection again to make sure it's been updated
    collection = Collection.where(owner_user_id: @user.id).first
    expect(collection.subjects_disabled).to be false
  end

 it "checks links work when enabled" do
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_content(@collection.title)
    expect(page).to have_content(@work.title)
    click_link @work.pages.first.title
    expect(page).to have_content("Transcription")
    expect(page).to have_selector('a', text: 'Texas')
    
  end

end