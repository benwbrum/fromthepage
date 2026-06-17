require 'spec_helper'

RSpec.describe 'IA import actions', order: :defined do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:ocr_title) { '[Letter to] Dear Garrison [manuscript]' }

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    login_as(owner, scope: :user)
  end

  after do |example|
    if example.metadata[:js]
      Collection.where(owner_user_id: owner.id).find_each(&:destroy!) if owner&.persisted?
      owner.destroy! if owner&.persisted?
    else
      DatabaseCleaner.clean
    end
  end

  it 'imports a work from IA' do
    VCR.use_cassette('ia/lettertosamuelma00estl', record: :none) do
      ia_work_count = IaWork.count
      ia_link = 'https://archive.org/details/lettertosamuelma00estl'
      visit dashboard_owner_path
      page.find('.tabs').click_link('Start A Project')
      click_link('Import From Archive.org', visible: false)
      fill_in 'detail_url', with: ia_link
      click_button('Import Work')
      page.accept_confirm if page.has_button?('Import Anyway')
      expect(page).to have_content('Manage Archive.org Import')
      select collection.title, from: 'collection_id'
      click_button('Publish Work')
      expect(page).to have_content('has been converted into a FromThePage work')
      expect(IaWork.count).to eq(ia_work_count + 1)
    end
  end

  it 'uses OCR when importing a work from IA' do
    VCR.use_cassette('ia/lettertodeargarr00mays', record: :none) do
      ia_work_count = IaWork.count
      ia_link = 'https://archive.org/details/lettertodeargarr00mays'
      visit dashboard_owner_path
      page.find('.tabs').click_link('Start A Project')
      click_link('Import From Archive.org', visible: false)
      fill_in 'detail_url', with: ia_link
      click_button('Import Work')
      page.accept_confirm if page.has_button?('Import Anyway')
      expect(page).to have_content('Manage Archive.org Import')
      expect(IaWork.count).to eq(ia_work_count + 1)
      page.check('use_ocr')
      select collection.title, from: 'collection_id'
      click_button('Publish Work')
      expect(page).to have_content(ocr_title)
      new_work = Work.find_by(title: ocr_title)
      first_page = new_work.pages.first
      expect(new_work.ocr_correction).to be
      expect(page).to have_content('has been converted into a FromThePage work')
      expect(page.find('h1')).to have_content(new_work.title)
      expect(first_page.source_text).not_to be_nil
    end
  end

  it 'tests ocr correction', js: true do
    ocr_work = create_ocr_work
    ocr_page = ocr_work.pages.first

    visit collection_read_work_path(owner, collection, ocr_work)
    expect(page).to have_content('This page is not corrected, please help correct this page')
    page.find('.work-page_title', text: ocr_page.title).click_link
    sleep(3)
    fill_in_editor_field('Test OCR Correction')
    find('#finish_button_top').click
    page.find('a.page-nav_prev').click
    expect(page).to have_content('Test OCR Correction')
    expect(page.find('.tabs')).to have_content('Correct')
    expect(ocr_page.reload.status_transcribed?).to be_truthy
  end

  it 'checks ocr/transcribe statistics', js: true do
    works = [create_work_with_statistics(ocr_correction: false), create_work_with_statistics(ocr_correction: true)]

    visit collection_path(owner, collection)
    expect(page).to have_content('Works')

    works.each do |work|
      completed = work.ocr_correction ? 'corrected' : 'transcribed'

      within(page.find('.collection-work', text: work.title)) do
        expect(page.find('.collection-work_stats', text: work.pages.count.to_s)).to have_content(completed)
      end
    end
  end

  def create_ocr_work
    create(:work,
           title: ocr_title,
           owner: owner,
           owner_user_id: owner.id,
           collection: collection,
           ocr_correction: true).tap do |work|
      create(:page, work: work, position: 1, source_text: 'OCR text')
      work.work_statistic.recalculate
      collection.works.reset
    end
  end

  def create_work_with_statistics(ocr_correction:)
    create(:work,
           owner: owner,
           owner_user_id: owner.id,
           collection: collection,
           ocr_correction: ocr_correction).tap do |work|
      create(:page, work: work, position: 1, status: :transcribed, source_text: 'Completed text')
      work.work_statistic.recalculate
      collection.works.reset
    end
  end
end
