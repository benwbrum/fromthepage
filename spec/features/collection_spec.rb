
require 'spec_helper'

describe "collection settings js tasks", :order => :defined do

  before :all do
    Capybara.javascript_driver = :webkit
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
    @work = @collection.works.second
    @rest_user = User.find_by(login: REST_USER)
    #add a user to be emailed
    @notify_user = User.find_by(login: ADMIN)
    #set up the restricted user not to be emailed
    notification = Notification.find_by(user_id: @rest_user.id)
    notification.add_as_collaborator = false
    notification.add_as_owner = false
    notification.save!
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
    ActionMailer::Base.deliveries.clear
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    #this user should not get an email (notifications turned off)
    select(@rest_user.name_with_identifier, from: 'collaborator_id')
    page.find('#collaborator_id+button').click
    expect(ActionMailer::Base.deliveries).to be_empty
    #this user should get an email
    select(@notify_user.name_with_identifier, from: 'collaborator_id')
    page.find('#collaborator_id+button').click
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(ActionMailer::Base.deliveries.first.to).to include @notify_user.email
    expect(ActionMailer::Base.deliveries.first.subject).to eq "You've been added to #{@collection.title}"
    expect(ActionMailer::Base.deliveries.first.body.encoded).to match("added you as a collaborator")
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
    find('#save_button_top').click
    page.click_link("Overview")
    expect(page.find('.page-preview')).to have_content("Collaborator test")
  end

  it "removes collaborators from a private collection" do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.user-label', text: @rest_user.display_name).find('a.remove').click
    page.find('.user-label', text: @notify_user.display_name).find('a.remove').click
    expect(page).not_to have_selector('.user-label', text: @rest_user.name_with_identifier)
  end

  it "checks that the removed user can't view the collection" do
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page).to have_content("Collections")
    expect(page).not_to have_content(@collection.title)
  end

  it "adds owners to a private collection" do
    ActionMailer::Base.deliveries.clear
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    #this user should not get an email (notifications turned off)
    select(@rest_user.name_with_identifier, from: 'user_id')
    page.find('#user_id+button').click
    expect(ActionMailer::Base.deliveries).to be_empty
    #this user should get an email
    select(@notify_user.name_with_identifier, from: 'user_id')
    page.find('#user_id+button').click
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(ActionMailer::Base.deliveries.first.to).to include @notify_user.email
    expect(ActionMailer::Base.deliveries.first.subject).to eq "You've been added to #{@collection.title}"
    expect(ActionMailer::Base.deliveries.first.body.encoded).to match("added you as a collaborator")
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
    visit dashboard_owner_path
    expect(page).to have_content("Owner Dashboard")
    expect(page).not_to have_selector('.owner-info')
  end

  it "removes owner from a private collection" do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.user-label', text: @rest_user.display_name).find('a.remove').click
    page.find('.user-label', text: @notify_user.display_name).find('a.remove').click
    expect(page).not_to have_selector('.user-label', text: @rest_user.name_with_identifier)
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
  
  context "inactive collection" do

    # Current Deed Counts for comparison
    active_count    = Deed.where(deed_type: DeedType::COLLECTION_ACTIVE).count
    inactive_count  = Deed.where(deed_type: DeedType::COLLECTION_INACTIVE).count

    it "transcribing works for active collections" do
      visit collection_display_page_path(@collection.owner, @collection, @page.work, @page.id)
      expect(page).to have_link('Transcribe')
    end

    it "toggles collection inactive" do
      login_as(@owner, :scope => :user)
      visit collection_path(@collection.owner, @collection)
      page.find('.tabs').click_link("Settings")
      page.click_link("Make Collection Inactive")
    end

    it "logs a deed when marked inactive" do
      deeds = Deed.where(deed_type: DeedType::COLLECTION_INACTIVE).count
      expect(deeds).to eq inactive_count + 1
    end

    it "transcribing doesn't work for inactive collections" do
      visit collection_display_page_path(@collection.owner, @collection, @page.work, @page.id)
      expect(page).not_to have_link('Transcribe')
    end

    it "toggles collection active" do
      login_as(@owner, :scope => :user)
      visit collection_path(@collection.owner, @collection)
      page.find('.tabs').click_link("Settings")
      page.click_link("Make Collection Active")
    end

    it "logs a deed when marked active" do
      deeds = Deed.where(deed_type: DeedType::COLLECTION_ACTIVE).count
      expect(deeds).to eq active_count + 1
    end
  end

  it "views completed works" do
    #first need to set a work as complete
    hidden_work = @collection.works.last
    hidden_work.pages.each do |p|
      p.status = "transcribed"
      p.source_text = "Transcription"
      p.save!
    end
    hidden_work.work_statistic.recalculate
    #check to see if the work is visible
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    #completed work shouldn't be visible at first
    expect(page.find('.maincol')).not_to have_content(hidden_work.title)
    #click button to show all works
    page.click_link("Show All")
    expect(page.find('.maincol')).to have_content(hidden_work.title)
    #click button to hide completed works
    page.click_link("Incomplete Works")
    expect(page.find('.maincol')).not_to have_content(hidden_work.title)
  end

  it "sorts works in works list", :js => true do
    Capybara.javascript_driver = :webkit
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Works List")
    expect(page).to have_content("Works")
    @collection.works.each do |w|
      expect(page).to have_content(w.title)
    end
    expect(page.find('.collection-work-stats').find('li:nth-child(2)')).to have_content @collection.works.pluck(:title).first
    expect(page.find('.collection-work-stats').find('li:last-child')).to have_content @collection.works.pluck(:title).last
    #sort by percent complete
    page.select('Percent Complete', from: 'sort_by')
    expect(page.find('.collection-work-stats').find('li:nth-child(2)')).to have_content @collection.works.order_by_completed.pluck(:title).first
    expect(page.find('.collection-work-stats').find('li:last-child')).to have_content @collection.works.order_by_completed.pluck(:title).last
    #sort by recent activity
    page.select('Recent Activity', from: 'sort_by')
    expect(page.find('.collection-work-stats').find('li:nth-child(2)')).to have_content @collection.works.order_by_recent_activity.pluck(:title).first
    expect(page.find('.collection-work-stats').find('li:last-child')).to have_content @collection.works.order_by_recent_activity.pluck(:title).last
  end

  it "views pages that need transcription" do
    login_as(@user, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    expect(page).to have_content("About")
    expect(page).to have_content("Works")
    page.click_link("Pages That Need Transcription")
    expect(page).to have_selector('h3', text: "Pages That Need Transcription")
    #make sure a page exists; don't specify which one
    expect(page).to have_selector('.work-page')
    click_link("Return to collection")
    expect(page).to have_content("About")
    expect(page).to have_content("Works")
  end

end

describe "collection spec (isolated)" do
  before :all do
    @factory_owner = create(:user, owner: true)
  end

  it 'updates collection statistics', :js => true do
      login_as(@factory_owner, :scope => :user)
      visit dashboard_owner_path(@factory_owner)
      expect(page).to have_content('Start A Project')
      page.find('.tabs').click_link('Start A Project')

      page.find(:css, '#create-empty-work').click

      select('Add New Collection', :from => 'work_collection_id')
      page.find('#new_collection').fill_in('collection_title', with: 'Stats Test Collection')
      click_button('Create Collection')
      expect(page).to have_content('Collection has been created')

      page.find(:css, '#create-empty-work').click

      fill_in('work_title', with: 'Stats Test Work')
      click_button('Create Work')
      page.find('#new_page')
      click_button('Save & New Work')

      visit dashboard_owner_path

      page.find('.collections').click_link('Stats Test Work')
      page.find('.tabs').click_link('Read')
      page.find('.maincol h4').click_link('Page 1')
      fill_in('page_source_text', with: 'Transcription')
      page.find('#save_button_top').click
      expect(page).to have_content('Saved')

      page.find('.breadcrumbs').click_link('Stats Test Collection')
      expect(page).to have_content("All works are fully transcribed.")
  end

  context 'Collection Settings' do
    before :all do
      @owner = User.find_by(login: OWNER)
    end
    before :each do
      login_as(@owner, :scope => :user)
      DatabaseCleaner.start
    end
    after :each do
      DatabaseCleaner.clean
    end

    let(:work_ocr){ create(:work, ocr_correction: true) }
    let(:work_no_ocr){ create(:work, ocr_correction: false) }
    let(:work_ocr_true){ create(:work, ocr_correction: true) }
    let(:work_ocr_false){ create(:work, ocr_correction: false) }
    let(:collection_ocr_mixed){ create(:collection, owner: @owner, works: [work_ocr, work_no_ocr]) }
    let(:collection_ocr_true) { create(:collection, owner: @owner, works: [work_ocr_true]) }
    let(:collection_ocr_false){ create(:collection, owner: @owner, works: [work_ocr_false]) }

    it 'shows OCR section' do
      visit edit_collection_path(@owner, collection_ocr_mixed)
      expect(page).to have_content(collection_ocr_mixed.title)
      expect(page).to have_content("OCR Correction")
    end
    it 'shows mixed OCR section buttons' do
      visit edit_collection_path(@owner, collection_ocr_mixed)
      expect(page).to have_content(collection_ocr_mixed.title)
      expect(page).to have_content("Enable OCR")
      expect(page).to have_content("Disable OCR")
    end
    it 'only shows enable OCR section buttons when all disabled' do
      visit edit_collection_path(@owner, collection_ocr_false)
      expect(page).to have_content(collection_ocr_false.title)
      expect(page).to have_content("Enable OCR")
      expect(page).not_to have_content("Disable OCR")
    end
    it 'only shows disable OCR section buttons when all disabled' do
      visit edit_collection_path(@owner, collection_ocr_true)
      expect(page).to have_content(collection_ocr_true.title)
      expect(page).to have_content("Disable OCR")
      expect(page).not_to have_content("Enable OCR")
    end
    it 'enables ocr' do
      visit edit_collection_path(@owner, collection_ocr_mixed)
      expect(page).to have_content(collection_ocr_mixed.title)
      click_link('Enable OCR')
      expect(page).to have_content("OCR correction has been enabled for all works.")
    end
    it 'disables ocr' do
      visit edit_collection_path(@owner, collection_ocr_mixed)
      expect(page).to have_content(collection_ocr_mixed.title)
      click_link('Disable OCR')
      expect(page).to have_content("OCR correction has been disabled for all works.")
    end
  end

  after :all do
    @factory_owner.collections.each do |c|
        c.destroy
    end
    @factory_owner.destroy
  end
end
