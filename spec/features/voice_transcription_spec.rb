require 'spec_helper'

describe "voice transcription", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @collection = Collection.second
    @work = @collection.works.first
    @page = @work.pages.first
    @article = @collection.articles.first
  end

  before :each do
    login_as(@owner, :scope => :user)
  end    


  it "checks for microphones (not enabled)" do
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
    expect(page).not_to have_selector('#start_img')
    #note
    expect(page).not_to have_selector('.voice-info')
    expect(page).not_to have_selector('#start_img_note')
    #translate
    page.find('.tabs').click_link('Translate')
    expect(page).not_to have_selector('.page-column_voice')
    expect(page).not_to have_selector('#start_img')
    #article
    visit collection_article_edit_path(@collection.owner, @collection, @article)
    expect(page).not_to have_selector('.article-editarea')
    expect(page).not_to have_selector('#start_img')
  end

  it "turns on voice transcription", :js => true do
    expect(@collection.voice_recognition).to be false
    visit edit_collection_path(@collection.owner, @collection)
    expect(page).not_to have_selector('#lang_opts')
    page.check 'collection_voice_recognition'
    sleep(2)
    expect(page).to have_selector('#lang_opts')
    click_button 'Save Changes'
    sleep(2)
    expect(Collection.second.voice_recognition).to be true
  end

it "checks for microphones (enabled)" do
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
    expect(page).to have_selector('#start_img')
    #note
    expect(page).to have_selector('#start_img_note')
    #translate
    page.find('.tabs').click_link('Translate')
    expect(page).to have_selector('.page-column_voice')
    expect(page).to have_selector('#start_img')
    #article
    visit collection_article_edit_path(@collection.owner, @collection, @article)
    expect(page).to have_selector('.article-editarea')
    expect(page).to have_selector('#start_img')
  end

  it "turns off voice transcription", :js => true do
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

end
