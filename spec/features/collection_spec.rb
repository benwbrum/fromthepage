require 'spec_helper'

describe "collection related tasks", :order => :defined do
  #Capybara.javascript_driver = :webkit


  before :all do

    @user = User.find_by(login: 'margaret')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @work = @collection.works.first
    @page = @work.pages.first
    @conventions = @collection.transcription_conventions
    @clean_conventions = ActionController::Base.helpers.strip_tags(@collection.transcription_conventions)
    @clean_conventions.gsub!(/\n/, ' ')
    @new_convention = "Collection level transcription convention"
    @work_convention = "Work level transcription conventions"
  end

  it "exports a collection" do
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.collection_title', text: @collection.title).click_link(@collection.title)
    page.find('.tabs').click_link("Export")
    expect(page).to have_content("Export All Works")
    expect(page).to have_content(@work.title)
    page.find('#btnExportAll').click
    expect(page.response_headers['Content-Type']).to eq 'application/zip'
  end

  it "checks for collection level transcription conventions" do
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@work.id}"
    page.find('.work-page', text: @page.title).click_link(@page.title)
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content @clean_conventions
  end

  it "changes work level transcription conventions" do
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@work.id}"
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content @conventions
    expect(page).to have_button('Revert', disabled: true)
    page.fill_in 'work_transcription_conventions', with: @work_convention
    click_button 'Save Changes'
    visit "/display/read_work?work_id=#{@work.id}"
    page.find('.work-page', text: @page.title).click_link(@page.title)
    page.find('.tabs').click_link("Transcribe")
    expect(page).not_to have_content @clean_conventions
    expect(page).to have_content @work_convention
    convention_work = @collection.works.first
    expect(convention_work.transcription_conventions).to eq @work_convention
  end

  it "changes conventions at collection level but not work level" do
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.collection_title', text: @collection.title).click_link(@collection.title)
    page.find('.tabs').click_link("Settings")
    page.fill_in 'collection_transcription_conventions', with: @new_convention
    click_button 'Save Changes'
    #check unchanged work for collection conventions
    work2 = @collection.works.second
    page2 = work2.pages.first
    visit "/display/read_work?work_id=#{work2.id}"
    page.find('.work-page', text: page2.title).click_link(page2.title)
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content @new_convention
    #check changed work for collection conventions
    visit "/display/read_work?work_id=#{@work.id}"
    page.find('.work-page', text: @page.title).click_link(@page.title)
    page.find('.tabs').click_link("Transcribe")
    expect(page).not_to have_content @new_convention
    expect(page).to have_content @work_convention
 
  end


    #having trouble getting the javascript driver to work in this test
  #it "reverts to collection level transcription conventions", :js => true do
  it "reverts to collection level transcription conventions" do
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@work.id}"
    page.find('.tabs').click_link("Settings")
    expect(page).not_to have_content @new_convention
    expect(page.find('#work_transcription_conventions')).to have_content @work_convention

    expect(page).to have_button('Revert')
=begin    
    #click_button 'Revert'


      expect(page).to have_content @new_convention

    expect(page).not_to have_content @work_convention
    convention_work = @collection.works.first
    expect(convention_work.transcription_conventions).to eq nil
    visit "/display/read_work?work_id=#{@work.id}"
    page.find('.work-page', text: @page.title).click_link(@page.title)
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content @new_convention
    expect(page).not_to have_content @work_convention
=end
  end

end
