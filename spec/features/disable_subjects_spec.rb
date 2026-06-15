# frozen_string_literal: true

require 'spec_helper'

describe 'disable subject linking' do
  LINKED_TEXT = '[[Canonical Subject|display subject]] [[Short Subject]]'

  let(:owner) { create(:unique_user, :owner) }
  let(:subjects_disabled) { true }
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      works: [],
      subjects_disabled: subjects_disabled
    )
  end
  let(:work) { create(:work, collection: collection, owner: owner, supports_translation: true) }
  let(:test_page) { create(:page, work: work, title: 'Disable Subjects Test Page') }

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    test_page
    login_as(owner, scope: :user)
  end

  after do |example|
    if example.metadata[:js]
      ArticlesCategory.where(article_id: collection.article_ids).delete_all
      collection.categories.destroy_all
      collection.destroy!
      owner.destroy!
    else
      DatabaseCleaner.clean
    end
  end

  it 'disables subject indexing in a collection', js: true do
    collection.update!(subjects_disabled: false)
    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Task Configuration')
    expect(page).to have_content('Enable subject indexing')
    uncheck('collection_subjects_enabled')

    expect(page).to have_content('Collection has been updated')
    expect(collection.reload.subjects_disabled).to be true
  end

  it 'hides collection-level subject items' do
    visit collection_path(owner, collection)
    # check for subject related items on Overview tab
    expect(page).to have_content(collection.title)
    expect(page).to have_content('Works')
    expect(page).not_to have_content('% indexed')
    expect(page).not_to have_content('Subject Categories')
    expect(page.find('.tabs')).not_to have_content('Subjects')
    # check for subject related items on Statistics tab
    page.find('.tabs').click_link('Statistics')
    expect(page).to have_content('Collaborators')
    expect(page).not_to have_content('Subjects')
    expect(page).not_to have_content('References')
    expect(page).not_to have_content('Pages indexed')
    expect(page).not_to have_content('New subjects')
    expect(page).not_to have_content('Indexing')
    # check for subject related items on Export tab
    page.find('.tabs').click_link('Export')
    expect(page).to have_content('Export Individual Works')
    expect(page).not_to have_content('Export Subjects')
    # check for subject related items on Collaborators tab
    page.find('.tabs').click_link('Collaborators')
    expect(page).to have_content('Contributions')
    expect(page).not_to have_content('Recent Subjects')
  end

  it 'hides work-level subject items' do
    visit collection_read_work_path(owner, collection, work)
    page.find('.tabs').click_link('Help')
    expect(page).to have_content('Transcribing')
    expect(page).not_to have_content('Linking Subjects')
    page.find('.tabs').click_link('Read')
    expect(page).to have_content(collection.title)
    expect(page).to have_content(work.title)
    expect(page).not_to have_content('Categories')
    page.find('.tabs').click_link('Contents')
    expect(page).to have_content('Actions')
    expect(page).not_to have_content('Annotate')
  end

  it 'preserves wiki-link text without creating subject links' do
    visit collection_read_work_path(owner, collection, work)
    page.find('.work-page_title', text: test_page.title).click_link(test_page.title)
    expect(page).not_to have_content('Autolink')
    expect(page).to have_content('A single newline')
    fill_in_editor_field(LINKED_TEXT)
    find('#save_button_top').click
    expect(page).to have_content(LINKED_TEXT)
    expect(page).to have_content('Transcription')
    expect(page).not_to have_selector('a', text: 'display subject')
    expect(page).not_to have_selector('a', text: 'Short Subject')
    page.find('.tabs').click_link('Translate')
    expect(page).not_to have_content('Autolink')
  end

  it 'exports wiki-link text without subject links when indexing is disabled' do
    test_page.update!(source_text: LINKED_TEXT)

    visit export_show_path(work_id: work.id)
    expect(page).to have_content(LINKED_TEXT)
    expect(page).not_to have_selector('a', text: 'display subject')
    expect(page).not_to have_selector('a', text: 'Short Subject')
  end

  context 'when subject indexing is enabled' do
    let(:subjects_disabled) { false }

    it 'enables subject indexing', js: true do
      collection.update!(subjects_disabled: true)
      visit collection_path(owner, collection)

      page.find('.tabs').click_link('Settings')
      page.find('.side-tabs').click_link('Task Configuration')
      expect(page).to have_content('Enable subject indexing')
      check('collection_subjects_enabled')

      expect(page).to have_content('Collection has been updated')
      expect(collection.reload.subjects_disabled).to be false
    end

    it 'creates links when enabled', js: true do
      visit collection_read_work_path(owner, collection, work)
      expect(page).to have_content(collection.title)
      expect(page).to have_content(work.title)
      page.find('.work-page_title', text: test_page.title).click_link(test_page.title)
      page.find('.tabs').click_link('Transcribe')
      fill_in_editor_field(LINKED_TEXT)
      find('#save_button_top').click

      expect(page).to have_content('Canonical Subject')
      expect(page).to have_content('Short Subject')
      click_link('Continue')

      page.find('.tabs').click_link('Overview')
      expect(page).to have_selector('a', text: 'display subject')
      expect(page).to have_selector('a', text: 'Short Subject')
      expect(page).not_to have_content('Canonical Subject')
    end

    it 'exports subject links when indexing is enabled' do
      test_page.update!(source_text: LINKED_TEXT)

      visit export_show_path(work_id: work.id)
      expect(page).to have_selector('a', text: 'display subject')
      expect(page).to have_selector('a', text: 'Short Subject')
    end
  end
end
