require 'spec_helper'

describe "editor actions" , :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @rest_user = User.find_by(login: REST_USER)
    collection_ids = Deed.where(user_id: @user.id).distinct.pluck(:collection_id)
    @collections = Collection.where(id: collection_ids)
    @collection = @collections.first
    @work = @collection.works.first
    @page = @work.pages.first
    @auth_work = Collection.last.works.second
    #set up the restricted user not to be emailed
    notification = Notification.find_by(user_id: @rest_user.id)
    notification.add_as_collaborator = false
    notification.save!
  end

  before :each do
    login_as(@user, :scope => :user)
  end

  it "checks that a restricted editor can't see a work" do
    logout(:user)
    login_as(@rest_user, :scope => :user)
    visit collection_read_work_path(@auth_work.owner, @auth_work.collection, @auth_work)
    page.find('.work-page_title', text: @work.pages.first.title).click_link
    expect(page.find('.tabs')).not_to have_content("Transcribe")
  end

  it "adds a user to a restricted work" do
    ActionMailer::Base.deliveries.clear
    logout(:user)
    login_as(@owner, :scope => :user)
    visit edit_collection_work_path(@auth_work.owner, @auth_work.collection, @auth_work)
    #this user should not get an email
    select(@rest_user.name_with_identifier, from: 'user_id')
    page.find('#user_id+button').click
    expect(ActionMailer::Base.deliveries).to be_empty
    #this user should get an email
    select(@user.name_with_identifier, from: 'user_id')
    page.find('#user_id+button').click
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(ActionMailer::Base.deliveries.first.to).to include @user.email
    expect(ActionMailer::Base.deliveries.first.subject).to eq "You've been added to #{@auth_work.title}"
    expect(ActionMailer::Base.deliveries.first.body.encoded).to match("added you as a collaborator")
  end

  it "checks that an editor with permissions can see a restricted work" do
    visit collection_read_work_path(@auth_work.owner, @auth_work.collection, @auth_work)
    page.find('.work-page_title', text: @work.pages.first.title).click_link
    expect(page.find('.tabs')).to have_content("Transcribe")
  end

  it "removes a collaborator from a restricted work" do
    logout(:user)
    login_as(@owner, :scope => :user)
    visit edit_collection_work_path(@auth_work.owner, @auth_work.collection, @auth_work)
    page.find('.user-label', text: @rest_user.name_with_identifier).find('a.remove').click
    expect(page).not_to have_selector('.user-label', text: @rest_user.name_with_identifier)
  end

  it "looks at a collection" do
    visit dashboard_watchlist_path
    page.find('h4', text: @collection.title).click_link(@collection.title)
    expect(page).to have_content("Works")    
    expect(page).to have_content(@work.title)
    expect(page).to have_content("Collection Footer")
    #check the tabs in the collection
    #Subjects
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("People")
    expect(page).to have_content("Places")
    #Statistics
    page.find('.tabs').click_link("Statistics")
    expect(page).to have_content("Collaborators")
    #make sure we don't have the owner tabs
    expect(page.find('.tabs')).not_to have_content("Settings")
    expect(page.find('.tabs')).not_to have_content("Export")
    expect(page.find('.tabs')).not_to have_content("Collaborators")
  end

  it "looks at a work" do
    visit collection_path(@collection.owner, @collection)
    page.find('.collection-work_title', text: @work.title).click_link
    expect(page).to have_content(@page.title)
    #Check the tabs in the work
    #About
    page.find('.tabs').click_link("About")
    expect(page).to have_content(@work.title)
    expect(page).to have_content("Description")
    #Versions
    page.find('.tabs').click_link("Versions")
    expect(page).to have_content("Revision 0")
    #Help
    page.find('.tabs').click_link("Help")
    expect(page).to have_content("Transcribing")
    expect(page).to have_content("Linking Subjects")
    #Contents
    page.find('.tabs').click_link("Contents")
    expect(page).to have_content("Page Title")
    expect(page).to have_content(@work.pages.last.title)
    within(page.find('tr', text: @work.pages.last.title)) do
      page.find('a', text: 'Transcribe').click
    end
    expect(page).to have_content("Transcription Conventions")
    expect(page).to have_selector("textarea")

  end

  it "looks at pages" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    expect(page).to have_content("please help transcribe this page")
    page.find('.work-page_title', text: @page.title).click_link
    page.find('#page_source_text')
    expect(page).to have_button('Preview')
    expect(page).to have_content(@page.title)
    expect(page).to have_content("Collection Footer")
    #Versions
    page.find('.tabs').click_link("Versions")
    expect(page).to have_content("revisions")
  end

  it "transcribes a page" do
    visit "/display/display_page?page_id=#{@page.id}"
    expect(page).to have_content("This page is not transcribed")
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Collection Footer")
    page.fill_in 'page_source_text', with: "Test Preview"
    click_button('Preview')
    expect(page).to have_content('Edit')
    expect(page).to have_content("Test Preview")
    click_button('Edit')
    expect(page).to have_content('Preview')
    page.fill_in 'page_source_text', with: "Test Transcription"
    click_button('Save Changes')
    page.click_link("Overview")
    expect(page).to have_content("Test Transcription")
    expect(page).to have_content("Facsimile")
  end

  it "translates a page" do
    @work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
    visit "/display/display_page?page_id=#{@work.pages.first.id}"
    page.find('.tabs').click_link("Translate")
    expect(page).to have_content("Collection Footer")
    page.fill_in 'page_source_translation', with: "Test Translation Preview"
    click_button('Preview')
    expect(page).to have_content('Edit')
    expect(page).to have_content("Test Translation Preview")
    click_button('Edit')
    expect(page).to have_content('Preview')
    page.fill_in 'page_source_translation', with: "Test Translation"
    click_button('Save Changes')
    expect(page).to have_content("Test Translation")
  end

  it "checks a plain user profile" do
    login_as(@user, :scope => :user)
    visit dashboard_path
    page.find('a', text: 'Your Profile').click
    expect(page).to have_content(@user.display_name)
    expect(page).to have_content("Recent Activity by #{@user.display_name}")
    expect(page).not_to have_selector('.columns')
  end

  it "tries to log in as another user" do
    visit "/users/masquerade/#{@owner.id}"
    expect(page.current_path).to eq collections_list_path
    expect(page.find('.dropdown')).not_to have_content @owner.display_name
    expect(page).to have_content @user.display_name
    expect(page).not_to have_selector('a', text: 'Undo Login As')
  end

  it "adds a note" do
    visit collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page)
    fill_in 'Write a new note...', with: "Test note"
    click_button('Submit')
    expect(page).to have_content "Note has been created"
    click_button('Save Changes')
    expect(page).to have_content('Saved')
  end

  it "tries to save transcription with unsaved note", :js => true do
    col = Collection.second
    test_page = col.works.first.pages.first
    visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
    text = Page.find_by(id: test_page.id).source_text
    fill_in('Write a new note...', with: "Test two")
    fill_in 'page_source_text', with: "Attempt to save"
    message = accept_alert do
      click_button('Save Changes')
    end
    sleep(2)
    expect(message).to have_content("You have unsaved notes.")
    new_text = Page.find_by(id: test_page.id).source_text
    #because of the note, page.source_text should not have changed
    expect(new_text).to eq text
    #save the note
    click_button('Submit')
    expect(test_page.notes.count).not_to be nil
  end

  it "deletes a note", :js => true do
    col = Collection.second
    test_page = col.works.first.pages.first
    visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
    title = test_page.notes.last.id
    page.find('.user-bubble_content', text: "Test two")
    page.click_link('', :href => "/notes/#{title}")
    sleep(3)
    expect(Note.find_by(id: title)).to be_nil
  end

  it "uses page arrows with unsaved transcription", :js => true do
    col = Collection.second
    test_page = col.works.first.pages.second
    #next page arrow
    visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
    fill_in 'page_source_text', with: "Attempt to save"
    message = accept_alert do
      page.click_link("Next page")
    end
    sleep(3)
    expect(message).to have_content("You have unsaved changes.")
    visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
    #previous page arrow - make sure it also works with notes
    fill_in('Write a new note...', with: "Test two")
    message = accept_alert do
      page.click_link("Previous page")
    end
    sleep(3)
    expect(message).to have_content("You have unsaved changes.")
  end

  it "filters list of pages the need transcription" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    expect(page).to have_content(@work.title)
    pages = @work.pages.limit(5)
    pages.each do |p|
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
    end

    #look at pages that need transcription
    click_button('Pages That Need Transcription')

    #first two pages are transcribed; they shouldn't show up
    expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.first.title)
    expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.second.title)
    #next three pages aren't transcribed; they shold show up
    expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.third.title)
    expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fourth.title)
    expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fifth.title)
    expect(page).to have_button('View All Pages')
    expect(page.find('.pagination_info')).to have_content(@work.pages.needs_transcription.count)

    #return to original list
    click_button('View All Pages')
    pages = @work.pages.limit(5)
    pages.each do |p|
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
    end
    expect(page).to have_button('Pages That Need Transcription')
    expect(page.find('.pagination_info')).to have_content(@work.pages.count)
  end

  it "filters list of pages the need translation" do
    @work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    expect(page).to have_content(@work.title)
    pages = @work.pages.limit(5)
    pages.each do |p|
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
    end

    #look at pages that need transcription
    click_button('Pages That Need Translation')
    #first page is translated; it shouldn't show up
    expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.first.title)
    #next three pages aren't translated; they shold show up
    expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.second.title)
    expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.third.title)
    expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fourth.title)
    expect(page).to have_button('View All Pages')
    expect(page.find('.pagination_info')).to have_content(@work.pages.needs_translation.count)

    #return to original list
    click_button('View All Pages')
    pages = @work.pages.limit(5)
    pages.each do |p|
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
    end
    expect(page).to have_button('Pages That Need Translation')
    expect(page.find('.pagination_info')).to have_content(@work.pages.count)
  end

  it "finds a page to transcribe" do
    visit collection_path(@collection.owner, @collection)
    expect(page).to have_selector('h1', text: @collection.title)
    expect(page).to have_content("About")
    expect(page).to have_content("Works")
    expect(page).not_to have_selector('a', text: "Start Transcribing")
    col = Collection.third
    visit collection_path(col.owner, col)
    expect(page).to have_selector('h1', text: col.title)
    expect(page).to have_content("About")
    expect(page).to have_content("Works")
    expect(page).to have_selector('a', text: "Start Transcribing")
    click_link("Start Transcribing")
    expect(page).to have_selector("#page_source_text")
  end

end
