require 'spec_helper'

RSpec.describe 'convention related tasks', order: :defined do
  let(:owner) { create(:unique_user, :owner) }
  let(:new_convention) { 'Collection level transcription convention' }
  let(:work_convention) { 'Work level transcription conventions' }
  let(:collection_conventions) { "Transcription conventions\nOriginal collection convention" }
  let(:clean_conventions) { 'Original collection convention' }
  let(:collection) do
    create(:collection,
           owner_user_id: owner.id,
           transcription_conventions: collection_conventions,
           works: [])
  end
  let(:work) { create_work_with_pages }
  let(:other_work) { create_work_with_pages }
  let(:work_page) { work.pages.first }

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    work
    other_work
    login_as(owner, scope: :user)
  end

  after do |example|
    if example.metadata[:js]
      Collection.where(owner_user_id: owner.id).find_each(&:destroy!) if owner&.persisted?
    else
      DatabaseCleaner.clean
    end
  end

  it 'checks for collection level transcription conventions' do
    visit collection_read_work_path(owner, collection, work)
    page.find('.work-page_title', text: work_page.title).click_link(work_page.title)
    open_transcription_if_available(work)
    expect(page).to have_content clean_conventions
    expect(page).to have_content('More help')
  end

  it 'changes work level transcription conventions', js: true do
    visit collection_read_work_path(owner, collection, work)
    page.find('.tabs').click_link('Settings')
    expect(page).to have_content('Transcription conventions')
    expect(page).not_to have_button('Revert')
    page.fill_in 'work_transcription_conventions', with: work_convention
    page.execute_script("$('#collection-settings-save').click()")
    expect(page).to have_content('Work updated successfully')
    visit collection_read_work_path(owner, collection, work)
    page.find('.work-page_title', text: work_page.title).click_link(work_page.title)
    open_transcription_if_available(work)
    expect(page).not_to have_content clean_conventions
    expect(page).to have_content work_convention
    expect(work.reload.transcription_conventions).to eq work_convention
  end

  it 'changes conventions at collection level but not work level', js: true do
    work.update!(transcription_conventions: work_convention)

    visit dashboard_owner_path
    page.find('.collection_title', text: collection.title).click_link(collection.title)
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Help Text')
    page.fill_in 'collection_transcription_conventions', with: new_convention
    page.execute_script("$('#collection-settings-save').click()")
    expect(page).to have_content('Collection has been updated')

    other_page = other_work.pages.second
    visit collection_read_work_path(owner, collection, other_work)
    page.find('.work-page_title', text: other_page.title).click_link(other_page.title)
    open_transcription_if_available(other_work)
    expect(page).to have_content new_convention

    visit collection_read_work_path(owner, collection, work)
    page.find('.work-page_title', text: work_page.title).click_link(work_page.title)
    open_transcription_if_available(work)
    expect(page).not_to have_content new_convention
    expect(page).to have_content work_convention
  end

  it 'reverts to collection level transcription conventions', js: true do
    collection.update!(transcription_conventions: new_convention)
    work.update!(transcription_conventions: work_convention)

    visit collection_read_work_path(owner, collection, work)
    page.find('.tabs').click_link('Settings')
    expect(work.reload.transcription_conventions).to eq work_convention
    expect(page).not_to have_content new_convention
    expect(page.find('#work_transcription_conventions')).to have_content work_convention
    click_button('Revert')
    expect(page).to have_content('Work updated successfully')
    expect(work.reload.transcription_conventions).to be_nil
    visit collection_read_work_path(owner, collection, work)
    page.find('.work-page_title', text: work_page.title).click_link(work_page.title)
    open_transcription_if_available(work)
    expect(page).to have_content new_convention
    expect(page).not_to have_content work_convention
  end

  def create_work_with_pages
    create(:work, owner: owner, owner_user_id: owner.id, collection: collection).tap do |created_work|
      create(:page, work: created_work, position: 1)
      create(:page, work: created_work, position: 2)
    end
  end

  def open_transcription_if_available(work)
    tab = work.reload.ocr_correction? ? 'Correct' : 'Transcribe'
    tabs = page.find('.tabs')
    tabs.click_link(tab) if tabs.has_link?(tab)
  end
end
