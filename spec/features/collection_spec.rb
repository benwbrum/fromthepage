
require 'spec_helper'

describe "collection settings js tasks", :order => :defined do

  before :all do
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

  it "sets collection to private", js: true do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Privacy & Access")

    expect(@collection.is_public).to eq true
    expect(page).to have_content("Collection privacy: Public")
    #check to see if Collaborators & API access are disabled
    expect(page.find('#users-list-collaborators')).to match_css('.disabled')
    expect(page.find_link('Edit Collaborators')).to match_css('[disabled]')
    expect(page).to have_field('collection[api_access]', disabled: true)
    #check to see if Blocked Users is enabled
    expect(page.find('#users-list-blocked')).not_to match_css('.disabled')
    expect(page.find_link('Block Users')).not_to match_css('[disabled]')

    page.click_link('Make Collection Private')
    @collection.reload
    expect(@collection.is_public).to eq false
    expect(page).to have_content("Collection privacy: Private")
    #check to see if Collaborators & API access are enabled
    expect(page.find('#users-list-collaborators')).not_to match_css('.disabled')
    expect(page.find_link('Edit Collaborators')).not_to match_css('[disabled]')
    expect(page).to have_field('collection[api_access]', disabled: false)
    #check to see if Blocked Users is disabled
    expect(page.find('#users-list-blocked')).to match_css('.disabled')
    expect(page.find_link('Block Users')).to match_css('[disabled]')
  end

  it "checks that a restricted user can't view the collection" do
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page.find('.maincol')).not_to have_content(@collection.title)
  end

  it "adds collaborators to a private collection" do
    ActionMailer::Base.deliveries.clear
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Privacy & Access")
    #this user should not get an email (notifications turned off)
    page.click_link 'Edit Collaborators'
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
    fill_in_editor_field('Collaborator test')
    find('#save_button_top').click
    page.click_link("Overview")
    expect(page.find('.page-preview')).to have_content("Collaborator test")
  end

  it "removes collaborators from a private collection" do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Privacy & Access")
    page.click_link 'Edit Collaborators'
    page.find('.user-label', text: @rest_user.display_name).find('button').click
    page.find('.user-label', text: @notify_user.display_name).find('button').click
    expect(page).not_to have_selector('.user-label', text: @rest_user.name_with_identifier)
  end

  it "checks that the removed user can't view the collection" do
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page.find('.maincol')).not_to have_content(@collection.title)
  end

  it "adds owners to a private collection" do
    ActionMailer::Base.deliveries.clear
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Privacy & Access")
    #this user should not get an email (notifications turned off)
    page.click_link 'Edit Owners'
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
    @rest_user.reload
    @rest_user.account_type = nil
    @rest_user.save
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page).to have_content("Collections")
    expect(page).to have_content(@collection.title)
    page.find('.maincol').find('a', text: @collection.title).click
    expect(page.find('.tabs')).to have_selector('a', text: 'Settings')
    expect(page.find('.tabs')).to have_selector('a', text: 'Export')
    expect(page.find('.tabs')).to have_selector('a', text: 'Collaborators')
    expect(page.find('.tabs')).to have_selector('a', text: 'Add Work')
    page.click_link("Settings")
    expect(page.find('.side-tabs')).not_to have_selector('a', text: 'Danger Zone')
    visit dashboard_owner_path
    expect(page).to have_content("Owner Dashboard")
    expect(page).not_to have_selector('.owner-info')
  end

  it "removes owner from a private collection" do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Privacy & Access")
    page.click_link 'Edit Owners'
    page.find('.user-label', text: @rest_user.display_name).find('button').click
    page.find('.user-label', text: @notify_user.display_name).find('button').click
    expect(page).not_to have_selector('.user-label', text: @rest_user.name_with_identifier)
  end

  it "checks removed owner permissions" do
    login_as(@rest_user, :scope => :user)
    visit dashboard_path
    expect(page.find('.maincol')).not_to have_content(@collection.title)
  end

  it "sets collection to public", js: true do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Privacy & Access")
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

    it "toggles collection inactive", js: true do
      login_as(@owner, :scope => :user)
      visit collection_path(@collection.owner, @collection)
      page.find('.tabs').click_link("Settings")
      page.find('.side-tabs').click_link("Danger Zone")
      expect(page).to have_content("Collection status: Active")
      page.choose("collection_is_active_false")
      sleep 0.5
      expect(page).to have_content("Collection status: Inactive")
    end

    it "logs a deed when marked inactive" do
      deeds = Deed.where(deed_type: DeedType::COLLECTION_INACTIVE).count
      expect(deeds).to eq inactive_count + 1
    end

    it "transcribing doesn't work for inactive collections" do
      unstarted_page = @page.work.pages.where(status: nil).first
      visit collection_display_page_path(@collection.owner, @collection, @page.work, unstarted_page)
      expect(page).to have_content('not active')
    end

    it "toggles collection active", js: true do
      login_as(@owner, :scope => :user)
      visit collection_path(@collection.owner, @collection)
      page.find('.tabs').click_link("Settings")
      page.find('.side-tabs').click_link("Danger Zone")
      page.choose("collection_is_active_true")
      sleep 0.5
      expect(page).to have_content("Collection status: Active")
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
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Works List")
    expect(page).to have_content("Works")
    @collection.works.each do |w|
      expect(page).to have_content(w.title)
    end
    expect(page.find('.collection-work-stats').find('tbody:nth-child(2)')).to have_content @collection.works.pluck(:title).first
    expect(page.find('.collection-work-stats').find('tbody:last-child')).to have_content @collection.works.pluck(:title).last
    #sort by percent complete
    page.find('.collection-work-stats').find('thead').find('th', text: 'Progress').click
    expect(page.find('.collection-work-stats').find('tbody:nth-child(2)')).to have_content @collection.works.order_by_completed.pluck(:title).first
    expect(page.find('.collection-work-stats').find('tbody:last-child')).to have_content @collection.works.order_by_completed.pluck(:title).last
    #sort by recent activity
    page.find('.collection-work-stats').find('thead').find('th', text: 'Most recent activity').click
    page.find('.collection-work-stats').find('thead').find('th', text: 'Most recent activity').click
    expect(page.find('.collection-work-stats').find('tbody:nth-child(2)')).to have_content @collection.works.order_by_recent_activity.pluck(:title).first
    expect(page.find('.collection-work-stats').find('tbody:last-child')).to have_content @collection.works.order_by_recent_activity.pluck(:title).last
  end

  it "views pages that need transcription" do
    login_as(@user, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    expect(page).to have_content("About")
    expect(page).to have_content("Works")
    page.click_link(I18n.t('collection.show.pages_need_correction_or_transcription'))
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
      old_count = Collection.all.count
      click_button('Create Collection')
      sleep 3
      expect(Collection.all.to_a.count).to eq(old_count+1)

      page.find(:css, '#create-empty-work').click
      sleep 3
      fill_in('work_title', with: 'Stats Test Work')
      click_button('Create Work')
      page.find('#new_page')
      click_button('Save & New Work')

      visit dashboard_owner_path

      page.find('.collections').click_link('Stats Test Collection')
      page.find('.collection-works .collection-work_title').click_link('Stats Test Work')
      page.find('.maincol h4').click_link('Page 1')
      fill_in_editor_field('Transcription')
      page.find('#finish_button_top').click

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
      page.find('.side-tabs').click_link('Task Configuration')
      expect(page).to have_content(collection_ocr_mixed.title)
      expect(page).to have_content("OCR Correction")
    end
    it 'shows mixed OCR section buttons' do
      visit edit_collection_path(@owner, collection_ocr_mixed)
      page.find('.side-tabs').click_link('Task Configuration')
      expect(page).to have_content(collection_ocr_mixed.title)
      expect(page).to have_content("Enable OCR")
      expect(page).to have_content("Disable OCR")
    end
    it 'only shows enable OCR section buttons when all disabled' do
      visit edit_collection_path(@owner, collection_ocr_false)
      page.find('.side-tabs').click_link('Task Configuration')
      expect(page).to have_content(collection_ocr_false.title)
      expect(page).to have_content("Enable OCR")
      expect(page).not_to have_content("Disable OCR")
    end
    it 'only shows disable OCR section buttons when all disabled' do
      visit edit_collection_path(@owner, collection_ocr_true)
      page.find('.side-tabs').click_link('Task Configuration')
      expect(page).to have_content(collection_ocr_true.title)
      expect(page).to have_content("Disable OCR")
      expect(page).not_to have_content("Enable OCR")
    end
    it 'enables ocr' do
      visit edit_collection_path(@owner, collection_ocr_mixed)
      page.find('.side-tabs').click_link('Task Configuration')
      expect(page).to have_content(collection_ocr_mixed.title)
      click_link('Enable OCR')
      expect(page).to have_content("OCR correction has been enabled for all works.")
    end
    it 'disables ocr' do
      visit edit_collection_path(@owner, collection_ocr_mixed)
      page.find('.side-tabs').click_link('Task Configuration')
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
