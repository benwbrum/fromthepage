# frozen_string_literal: true

require 'spec_helper'

describe 'owner view - collection' do
  before do
    DatabaseCleaner.start
    collaborator_deeds
    login_as(owner, scope: :user)
  end

  after do
    DatabaseCleaner.clean
  end

  let(:owner) do
    create(
      :unique_user,
      :owner,
      display_name: 'Test Owner',
      account_type: 'Trial',
      start_date: Time.zone.local(2024, 1, 15)
    )
  end
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      subjects_disabled: false,
      works: build_list(:work_with_pages, 2, owner: owner)
    )
  end
  let(:works) { collection.works }
  let(:work) { works.first }
  let(:transcriber) { create(:unique_user, display_name: 'Test Transcriber', activity_email: true) }
  let(:editor) { create(:unique_user, display_name: 'Test Editor', activity_email: true) }
  let(:indexer) { create(:unique_user, display_name: 'Test Indexer', activity_email: true) }
  let(:collaborator_deeds) do
    [
      create(:deed, user: transcriber, collection: collection, work: work, page: work.pages.first),
      create(
        :deed,
        deed_type: DeedType::PAGE_EDIT,
        user: editor,
        collection: collection,
        work: work,
        page: work.pages.first
      ),
      create(
        :deed,
        deed_type: DeedType::PAGE_INDEXED,
        user: indexer,
        collection: collection,
        work: work,
        page: work.pages.first
      )
    ]
  end

  it 'looks at owner tabs' do
    visit dashboard_owner_path
    expect(page).to have_selector('.owner-info')
    expect(page).to have_content('Trial account since Jan 15, 2024')
    # look at owner stats in dashboard
    expect(page.find('.owner-counters .counter[1]')['data-prefix'].to_i).to eq 1
    expect(page.find('.owner-counters .counter[2]')['data-prefix'].to_i).to eq works.count
    # look at tabs
    page.find('.tabs').click_link('Start A Project')
    expect(page.current_path).to eq '/dashboard/startproject'
    expect(page).to have_content('Upload PDF or ZIP File')
    page.find('.tabs').click_link('Your Collections')
    expect(page.current_path).to eq dashboard_owner_path
  end

  it 'looks at the owner statistics tab' do
    visit dashboard_owner_path
    page.find('.tabs').click_link('Summary')
    expect(page).to have_selector('.collection-stats_counters')
    expect(page).to have_content('Statistics from')
    expect(page.find('.collection-stats_counters[1] .counter[1]')['data-prefix'].to_i).to eq works.count
    expect(page.find('.collection-users')).to have_content('Transcribing')
    expect(page.find('.collection-users')).to have_content('Editing')
    expect(page.find('.collection-users')).to have_content('Indexing')
    expect(page.find('.collection-users')).to have_content(transcriber.display_name)
    expect(page.find('.collection-users')).to have_content(editor.display_name)
    expect(page.find('.collection-users')).to have_content(indexer.display_name)
  end

  it 'looks at subjects tab' do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link('Subjects')
    expect(page).to have_content('Categories')
    expect(page).to have_content('People')
    expect(page).to have_content('Places')
  end

  it 'looks at the collection statistics tab' do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link('Statistics')
    expect(page).to have_content('Works')
    expect(page).to have_content('Collaborators')
    expect(page.find('.collection-stats_counters[1] .counter[1]')['data-prefix'].to_i).to eq works.count
  end

  it 'looks at works list tab' do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link('Works List')
    expect(page).to have_content('Works')
    works.each do |collection_work|
      expect(page).to have_content(collection_work.title)
    end
  end

  it 'looks at settings tab' do
    visit "/collection/show?collection_id=#{collection.id}"
    page.find('.tabs').click_link('Settings')
    expect(page).to have_content(collection.title)
    expect(page).to have_content('Danger Zone')
  end

  it 'looks at export tab' do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link('Export')
    expect(page).to have_content(collection.title)
    works.each do |collection_work|
      expect(page).to have_content(collection_work.title)
    end
  end

  it 'looks at collaborators tab' do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link('Collaborators')
    expect(page).to have_content(collection.title)
    expect(page).to have_content('Contributions Between')
    expect(page).to have_content('Active Collaborators')
    expect(page).to have_content('All Collaborator Emails')

    within '#collaborators' do
      [transcriber, editor, indexer].each do |collaborator|
        expect(page).to have_content(collaborator.email)
      end
    end
  end
end
