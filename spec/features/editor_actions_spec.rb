require 'spec_helper'

describe "editor actions" do

  before :all do
    @user = User.find_by(login: 'hermione')
    collection_ids = Deed.where(:user_id => @user.id).select(:collection_id).distinct.limit(5).map(&:collection_id)
    @collections = Collection.where(:id => collection_ids).order_by_recent_activity
    @collection = @collections.first
    @work = @collection.works.first
    @page = @work.pages.first
    @auth = TranscribeAuthorization.find_by(user_id: @user.id)
  end

  it "checks that an editor with permissions can see a restricted work" do
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@auth.work_id}"
    click_link @work.pages.first.title
    expect(page.find('.tabs')).to have_content("Transcribe")
  end

  it "checks that a restricted editor can't see a work" do
    @user = User.find_by(login: 'ron')
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@auth.work_id}"
    click_link @work.pages.first.title
    expect(page.find('.tabs')).not_to have_content("Transcribe")
  end

  it "looks at a collection" do
      login_as(@user, :scope => :user)
      visit dashboard_watchlist_path
      page.find('h4').click_link(@collection.title)
      expect(page).to have_content("Works")    
      expect(page).to have_content(@work.title)
      #check the tabs in the collection
      #Subjects
      page.find('.tabs').click_link("Subjects")
      expect(page).to have_content("People")
      expect(page).to have_content("Places")
      #Statistics
      page.find('.tabs').click_link("Statistics")
      expect(page).to have_content("Work Progress")
      #make sure we don't have the owner tabs
      expect(page.find('.tabs')).not_to have_content("Settings")
      expect(page.find('.tabs')).not_to have_content("Export")
      expect(page.find('.tabs')).not_to have_content("Collaborators")

  end

  it "looks at a work" do
    login_as(@user, :scope => :user)
      visit "/collection/show?collection_id=#{@collection.id}"
      click_link @work.title
      expect(page).to have_content(@page.title)
      #Check the tabs in the work
      #About
      page.find('.tabs').click_link("About")
      expect(page).to have_content(@work.title)
      expect(page).to have_content("Description")
      #Contents
      page.find('.tabs').click_link("Contents")
      expect(page).to have_content("Page Title")
      expect(page).to have_content(@page.title)
      #Versions
      page.find('.tabs').click_link("Versions")
      expect(page).to have_content("Revision 0")
      #Help
      page.find('.tabs').click_link("Help")
      expect(page).to have_content("Transcribing")
      expect(page).to have_content("Linking Subjects")
  end

  it "looks at pages" do
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_content("please help transcribe this page")
    click_link @page.title
    expect(page).to have_content("Facsimile")
    expect(page).to have_content(@page.title)
    #Versions
    page.find('.tabs').click_link("Versions")
    expect(page).to have_content("revisions")

  end

  it "transcribes a page" do
    login_as(@user, :scope => :user)
    visit "/display/display_page?page_id=#{@page.id}"
    save_and_open_page
    expect(page).to have_content("This page is not transcribed")
    page.find('.tabs').click_link("Transcribe")
    expect('#page_status').to have_content("Transcription status not set")
    page.fill_in 'page_source_text', with: "Test Transcription"
    click_button('Save Changes')
    expect(page).to have_content("Test Transcription")
    expect(page).to have_content("Facsimile")
    expect(@page.status).to be "" 
  end

  it "translates a page" do
    login_as(@user, :scope => :user)
    @work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
    visit "/display/display_page?page_id=#{@work.pages.first.id}"
    page.find('.tabs').click_link("Translate")
    expect(page).to have_content("Translation")
    page.fill_in 'page_source_translation', with: "Test Translation"
    click_button('Save Changes')
    expect(page).to have_content("Test Translation")
  end

  it "adds a note" do
    login_as(@user, :scope => :user)
    visit "/display/display_page?page_id=#{@page.id}"
    note = page.find('#note_body')
    fill_in 'note_body', with: "Test note"
    click_button('Submit')
    expect(page).to have_content "Note has been created"
    #delete the note
  end

  it "links a categorized subject" do
    login_as(@user, :scope => :user)
    @page = @work.pages.last
    visit "/display/display_page?page_id=#{@page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|Hogwarts]]"
    click_button('Save Changes')
    expect(page).to have_content("Hogwarts")
    #this functionality is currently not working for my test machine
    #page.find('a', text: 'Hogwarts').click
    #expect(page).to have_content("Category")
  end

  #it checks to make sure the subject is on the page

  it "looks at subjects in a collection" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Categories")
    categories = Category.where(collection_id: @collection.id)
    categories.each do |c|
      column = page.find('div.category-tree')
      expect(column).to have_content(c.title)
      column.click_link c.title
      c.articles.each do |a|
        expect(page).to have_content(a.title)
      end
    end
  end

#not yet implemented
  it "clicks the links to look at the information for a subject" do

  end

end