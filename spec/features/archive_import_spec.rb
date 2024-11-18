require 'spec_helper'

describe 'IA import actions', order: :defined do
  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
    @works = @owner.owner_works
    @title = '[Letter to] Dear Garrison [manuscript]'
  end

  before :each do
    login_as(@owner, scope: :user)
  end

  it 'imports a work from IA', js: true do
    VCR.use_cassette('ia/lettertosamuelma00estl', record: :new_episodes) do
      ia_work_count = IaWork.all.count
      ia_link = 'https://archive.org/details/lettertosamuelma00estl'
      visit dashboard_owner_path
      page.find('.tabs').click_link('Start A Project')
      page.find(:css, '#import-internet-archive').click
      click_link('Import From Archive.org')
      fill_in 'detail_url', with: ia_link
      click_button('Import Work')
      click_button('Import Anyway') if page.has_button?('Import Anyway')
      expect(page).to have_content('Manage Archive.org Import')
      select @collection.title, from: 'collection_id'
      click_button('Publish Work')
      expect(page).to have_content('has been converted into a FromThePage work')
      expect(ia_work_count + 1).to eq IaWork.all.count
    end
  end

  it 'uses OCR when importing a work from IA', js: true do
    VCR.use_cassette('ia/lettertodeargarr00mays', record: :new_episodes) do
      ia_work_count = IaWork.all.count
      ia_link = 'https://archive.org/details/lettertodeargarr00mays'
      visit dashboard_owner_path
      page.find('.tabs').click_link('Start A Project')
      page.find(:css, '#import-internet-archive').click
      click_link('Import From Archive.org')
      fill_in 'detail_url', with: ia_link
      click_button('Import Work')
      click_button('Import Anyway') if page.has_button?('Import Anyway')
      expect(ia_work_count + 1).to eq IaWork.all.count
      expect(page).to have_content('Manage Archive.org Import')
      page.check('use_ocr')
      select @collection.title, from: 'collection_id'
      click_button('Publish Work')
      new_work = Work.find_by(title: @title)
      first_page = new_work.pages.first
      expect(new_work.ocr_correction).to be
      expect(page).to have_content('has been converted into a FromThePage work')
      expect(page.find('h1')).to have_content(new_work.title)
      expect(first_page.source_text).not_to be_nil
    end
  end

  it 'tests ocr correction', js: true do
    @ocr_work = Work.find_by(title: @title)
    @ocr_page = @ocr_work.pages.first
    visit collection_read_work_path(@ocr_work.owner, @ocr_work.collection, @ocr_work)
    expect(page).to have_content('This page is not corrected, please help correct this page')
    page.find('.work-page_title', text: @ocr_page.title).click_link
    sleep(3)
    fill_in_editor_field('Test OCR Correction')
    find('#finish_button_top').click
    sleep(3)
    page.find('a.page-nav_prev').click
    expect(page).to have_content('Test OCR Correction')
    expect(page.find('.tabs')).to have_content('Correct')
    @ocr_page = @ocr_work.pages.first
    expect(@ocr_page.status_transcribed?).to be_truthy
  end

  it 'checks ocr/transcribe statistics', js: true do
    visit collection_path(@collection.owner, @collection)
    expect(page).to have_content('Works')
    @collection.works.each do |w|
      completed = w.ocr_correction ? 'corrected' : 'transcribed'

      within(page.find('.collection-work', text: w.title)) do
        expect(page.find('.collection-work_stats', text: w.pages.count.to_s)).to have_content(completed)
      end
    end
  end
end
