
require 'spec_helper'

describe "collection settings js tasks", :order => :defined do

  before :all do
    Capybara.javascript_driver = :webkit
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
    @work = @collection.works.second
    @rest_user = User.find_by(login: REST_USER)
    @page = @work.pages.first
    @wording = "Click microphone to dictate"
    @article = @collection.articles.first

  end

  it "sets collection to private" do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    #check to see if Collaborators are visible
    expect(page).not_to have_content("Collection Collaborators")
    page.click_link('Make Collection Private')
    #check to see if Collaborators are visible
    expect(page).to have_content("Collection Collaborators")
  end

  it "checks that a restricted user can't view the collection" do
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page).to have_content("Collections")
    expect(page).not_to have_content(@collection.title)
  end

  it "adds collaborators to a private collection" do
    #hack because of the problems with the select2 code
    @collection.collaborators << @rest_user
  end

  it "checks that an added user can edit a work in the collection" do
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page).to have_content("Collections")
    expect(page).to have_content(@collection.title)
    page.find('.maincol').find('a', text: @collection.title).click
    expect(page.find('.tabs')).to have_selector('a', text: 'Overview')
    expect(page.find('.tabs')).to have_selector('a', text: 'Statistics')
    expect(page.find('.tabs')).to have_selector('a', text: 'Subjects')
    expect(page.find('.tabs')).not_to have_selector('a', text: 'Settings')
    page.find('.maincol').find('a', text: @work.title).click
    expect(page.find('h1')).to have_content(@work.title)
    page.find('.maincol').find('a', text: @work.pages.first.title).click
    expect(page.find('h1')).to have_content(@work.pages.first.title)
    page.fill_in 'page_source_text', with: "Collaborator test"
    click_button('Save Changes')
    page.click_link("Overview")
    expect(page.find('.page-preview')).to have_content("Collaborator test")
  end

  it "removes collaborators from a private collection" do
    #hack because of problems with select2
    @collection.collaborators.delete(@rest_user)
  end

  it "checks that the removed user can't view the collection" do
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page).to have_content("Collections")
    expect(page).not_to have_content(@collection.title)
  end

  it "adds owners to a private collection" do
    @rest_user.owner = true
    @rest_user.save!
    @collection.owners << @rest_user
  end

  it "checks added owner permissions" do
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page).to have_content("Collections")
    expect(page).to have_content(@collection.title)
    page.find('.maincol').find('a', text: @collection.title).click
    expect(page.find('.tabs')).to have_selector('a', text: 'Settings')
    expect(page.find('.tabs')).to have_selector('a', text: 'Export')
    expect(page.find('.tabs')).to have_selector('a', text: 'Collaborators')
    expect(page.find('.tabs')).to have_selector('a', text: 'Add Work')
  end

  it "removes owner from a private collection" do
    @collection.owners.delete(@rest_user)
  end

  it "checks removed owner permissions" do
   login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page).to have_content("Collections")
    expect(page).not_to have_content(@collection.title)
  end

  it "sets collection to public" do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.click_link("Make Collection Public")
  end

  it "views completed works" , :js => true do
    #first need to set a work as complete
    hidden_work = @collection.works.last
    hidden_work.pages.each do |p|
      p.status = "transcribed"
      p.save!
    end
    #check to see if the work is visible
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    #completed work shouldn't be visible at first
    expect(page.find('.maincol')).not_to have_content(hidden_work.title)
    #check checkbox to show all works    
    page.check('hide_completed')
    expect(page.find('.maincol')).to have_content(hidden_work.title)
    #check checkbox to hide completed works
    page.uncheck('hide_completed')
    expect(page.find('.maincol')).not_to have_content(hidden_work.title)
  end

  it "sorts works in works list", :js => true do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Works List")
    expect(page).to have_content("Works")
    @collection.works.each do |w|
      expect(page).to have_content(w.title)
    end
    expect(page.find('.collection-work-stats').find('li:nth-child(2)')).to have_content @collection.works.first.title
    expect(page.find('.collection-work-stats').find('li:last-child')).to have_content @collection.works.last.title
    #sort by percent complete
    page.select('Percent Complete', from: 'sort_by')
    expect(page.find('.collection-work-stats').find('li:nth-child(2)')).to have_content @collection.works.order_by_completed.first.title
    expect(page.find('.collection-work-stats').find('li:last-child')).to have_content @collection.works.order_by_completed.pluck(:title).last
    #sort by recent activity
    page.select('Recent Activity', from: 'sort_by')
    expect(page.find('.collection-work-stats').find('li:nth-child(2)')).to have_content @collection.works.order_by_recent_activity.first.title
    expect(page.find('.collection-work-stats').find('li:last-child')).to have_content @collection.works.order_by_recent_activity.pluck(:title).last
  end
=begin
  it "checks for microphones (not enabled)" do
    login_as(@owner, :scope => :user)
    #first set the work to translation
    @work.supports_translation = true
    @work.save
     #transcribe
    visit collection_transcribe_page_path(@collection.owner, @collection, @work, @page)
    if page.has_content?('Facsimile')
      page.find('.tabs').click_link('Transcribe')
    end
    #transcription div
    expect(page).not_to have_selector('.page-column_voice')
    #note
    expect(page).not_to have_selector('.voice-info')
    expect(page).not_to have_content(@wording)
    #translate
   page.find('.tabs').click_link('Translate')
    expect(page).not_to have_selector('.page-column_voice')
    #article
    visit collection_article_edit_path(@collection.owner, @collection, @article)
    expect(page).not_to have_content(@wording)
    expect(page).not_to have_selector('.article-editarea')
  end

  it "turns on voice transcription", :js => true do
    login_as(@owner, :scope => :user)
    expect(@collection.voice_recognition).to be false
    visit edit_collection_path(@collection.owner, @collection)
    expect(page).not_to have_selector('#lang_opts')
    page.check 'collection_voice_recognition'
    expect(page).to have_selector('#lang_opts')
    click_button 'Save Changes'
    sleep(2)
    expect(Collection.second.voice_recognition).to be true
  end

  it "checks for microphones (enabled)" do
    login_as(@owner, :scope => :user)
    #first set the work to translation
    @work.supports_translation = true
    @work.save
    #transcribe
    visit collection_transcribe_page_path(@collection.owner, @collection, @work, @page)
    if page.has_content?('Facsimile')
      page.find('.tabs').click_link('Transcribe')
    end
    #transcription div
    expect(page).to have_selector('.page-column_voice')
    expect(page.find('.page-column_voice')).to have_content(@wording)
    #note
    expect(page.find('.user-bubble_form_footer')).to have_content(@wording)
    #expect(page.find('.voice-info')).to have_content(@wording)
    #translate
    page.find('.tabs').click_link('Translate')
    expect(page).to have_selector('.page-column_voice')
    expect(page.find('.page-column_voice')).to have_content(@wording)
    #article
    visit collection_article_edit_path(@collection.owner, @collection, @article)
    expect(page.find('.article-editarea')).to have_content(@wording)
  end

  it "turns off voice transcription", :js => true do
    login_as(@owner, :scope => :user)
    @collection = Collection.second
    expect(@collection.voice_recognition).to be true
    visit edit_collection_path(@collection.owner, @collection)
    page.uncheck 'collection_voice_recognition'
    expect(page).not_to have_selector('#lang_opts')
    click_button 'Save Changes'
    #turn off work translation
    @work.supports_translation = false
    @work.save
    sleep(2)
    expect(Collection.second.voice_recognition).to be false
  end
=end
end

=begin
    #I can't access the select2 dropdown, but this code was the closest
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    select2([@rest_user.display_name], '#collaborators')
    page.find('#collaborators').find('button', text: 'Add').trigger(:submit)
=end

