require 'spec_helper'

describe "convention related tasks", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
    @work = @collection.works.last
    @page = @work.pages.first
    @conventions = @collection.transcription_conventions
    @clean_conventions = ActionController::Base.helpers.strip_tags(@collection.transcription_conventions)
    @clean_conventions.gsub!(/\n/, ' ')
    @new_convention = "Collection level transcription convention"
    @work_convention = "Work level transcription conventions"
    if @work.ocr_correction == true
      @tab = "Correct"
    else
      @tab = "Transcribe"
    end
  end

  before :each do
    login_as(@owner, :scope => :user)
  end    

  it "checks for collection level transcription conventions" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @page.title).click_link(@page.title)
    #if the page isn't already transcribed, must go to Transcribe tab
    if page.has_content?("Facsimile")
      page.find('.tabs').click_link(@tab)
    end
    expect(page).to have_content @clean_conventions
    expect(page).to have_content("More help")
  end

  it "changes work level transcription conventions" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content @conventions
    expect(page).to have_button('Revert', disabled: true)
    page.fill_in 'work_transcription_conventions', with: @work_convention
    click_button 'Save Changes'
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @page.title).click_link(@page.title)
    if page.has_content?("Facsimile")
      page.find('.tabs').click_link(@tab)
    end
    expect(page).not_to have_content @clean_conventions
    expect(page).to have_content @work_convention
    convention_work = Work.find_by(id: @work.id)
    expect(convention_work.transcription_conventions).to eq @work_convention
  end

  it "changes conventions at collection level but not work level" do
    visit dashboard_owner_path
    page.find('.collection_title', text: @collection.title).click_link(@collection.title)
    page.find('.tabs').click_link("Settings")
    page.fill_in 'collection_transcription_conventions', with: @new_convention
    click_button 'Save Changes'
    #check unchanged work for collection conventions
    work2 = @collection.works.first
    page2 = work2.pages.first
    visit collection_read_work_path(work2.collection.owner, work2.collection, work2)
    page.find('.work-page_title', text: page2.title).click_link(page2.title)
    expect(page).to have_content @new_convention
    #check changed work for collection conventions
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @page.title).click_link(@page.title)
    if page.has_content?("Facsimile")
      page.find('.tabs').click_link(@tab)
    end
    expect(page).not_to have_content @new_convention
    expect(page).to have_content @work_convention
  end

  it "reverts to collection level transcription conventions", :js => true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.tabs').click_link("Settings")
    convention_work = Work.find_by(id: @work.id)
    expect(convention_work.transcription_conventions).to eq @work_convention
    expect(page).not_to have_content @new_convention
    expect(page.find('#work_transcription_conventions')).to have_content @work_convention
    expect(page).to have_button('Revert')
    page.find_button('Revert').trigger(:click)
    sleep(3)
    convention_work = Work.find_by(id: @work.id)
    expect(convention_work.transcription_conventions).to eq nil
    visit "/display/read_work?work_id=#{@work.id}"
    page.find('.work-page_title', text: @page.title).click_link(@page.title)
    if page.has_content?("Facsimile")
      page.find('.tabs').click_link(@tab)
    end
    expect(page).to have_content @new_convention
    expect(page).not_to have_content @work_convention
  end

end

