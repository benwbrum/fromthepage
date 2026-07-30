# Note - this test must fall at the very end of the features specs
require 'spec_helper'

RSpec.describe 'testing deletions' do
  let(:owner) { create(:unique_user, :owner) }

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    login_as(owner, scope: :user)
  end

  after do |example|
    if example.metadata[:js]
      Collection.where(owner_user_id: owner.id).find_each(&:destroy!) if owner&.persisted?
    else
      DatabaseCleaner.clean
    end
  end

  it 'blanks out the data in a collection' do
    collection = create_collection_with_work_pages
    collection.pages.each do |page_record|
      create(:page_version, page_id: page_record.id, user_id: owner.id, page_version: 1)
      create(:deed, page: page_record, work: page_record.work, collection: collection, user: owner)
    end

    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Danger Zone')
    expect(page).to have_content('Please use caution')
    expect(page).to have_content('Blank Collection')
    page.find('a', text: 'Blank Collection').click
    expect(page.current_path).to eq "/#{owner.slug}/#{collection.slug}"
    pages = Page.where(work_id: collection.works.ids)
    pages.each do |collection_page|
      expect(collection_page.status_new?).to be_truthy
      expect(collection_page.page_versions.first.page_version).to eq 0
    end
    expect(Deed.where(page_id: pages.ids)).to be_empty
  end

  it 'deletes a document set' do
    collection = create_collection_with_work_pages
    document_sets = create_list(:document_set, 2,
                                :public,
                                collection: collection,
                                owner: owner,
                                owner_user_id: owner.id)
    count = owner.document_sets.count

    visit dashboard_owner_path
    page.find('.maincol').find('a', text: collection.title).click
    page.find('.tabs').click_link('Sets')
    expect(page).to have_content("Document Sets for #{collection.title}")
    within(page.find('#sets')) do
      within(page.find('tr', text: document_sets.first.title)) do
        page.find('a', text: 'Delete').click
      end
    end
    expect(owner.document_sets.count).to eq(count - 1)
    expect(page).not_to have_content(document_sets.first.title)
    expect(page).to have_content(document_sets.last.title)
  end

  it 'deletes a page' do
    collection = create_collection_with_work_pages
    work = collection.works.reload.first
    count = work.pages.count
    test_page = work.pages.first
    create(:page_version, page_id: test_page.id, user_id: owner.id)
    create(:deed, page: test_page, work: work, collection: collection, user: owner)

    visit dashboard_owner_path
    page.find('.maincol').click_link(collection.title)
    page.find('.tabs').click_link('Works List')
    page.find('#works-table').find('a', text: work.title).click
    expect(page).to have_content(work.title)
    expect(page).to have_content(test_page.title)
    page.find('.work-page_title', text: test_page.title).click_link(test_page.title)
    page.find('.tabs').click_link('Settings')
    page.find('a', text: 'Delete Page').click
    expect(work.pages.count).to eq(count - 1)
    expect(Deed.where(page_id: test_page.id)).to be_empty
    expect(test_page.page_versions).to be_empty
  end

  it 'deletes a work', js: true do
    collection = create_collection_with_work_pages
    work = collection.works.reload.first
    work_count = Work.count
    page_count = work.pages.count
    expect(page_count).to be > 0
    path = Rails.root.join('public', 'images', 'uploaded', work.id.to_s)

    visit dashboard_owner_path
    page.find('.maincol').click_link(collection.title)
    page.all('.collection-works a', text: work.title).first.click
    page.find('.tabs').click_link('Settings')
    expect(page).to have_content(work.title)
    click_link 'Danger Zone'
    accept_confirm do
      click_link('Delete Work')
    end
    expect(page).to have_content('Work deleted successfully')
    expect(Work.count).to eq(work_count - 1)
    expect(work.pages).to be_empty
    expect(Deed.where(work_id: work.id)).to be_empty
    expect(Dir.exist?(path)).to be false
  end

  it 'deletes a collection' do
    collection = create_collection_with_work_pages
    create(:article, collection: collection)
    create(:document_set, :public, collection: collection, owner: owner, owner_user_id: owner.id)
    count = owner.all_owner_collections.count
    expect(collection.works.count).to be > 0
    expect(collection.articles.count).to be > 0
    expect(collection.document_sets.count).to be > 0

    visit collection_path(owner, collection)
    click_link('Show All') if page.has_link?('Show All')
    collection.works.each do |work|
      expect(page).to have_content(work.title)
    end
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Danger Zone')
    expect(page).to have_content('Please use caution')
    expect(page).to have_selector('a', text: 'Delete Collection')
    page.find('a', text: 'Delete Collection').click
    expect(owner.all_owner_collections.count).to eq(count - 1)
    expect(Work.where(collection_id: collection.id)).to be_empty
    expect(Article.where(collection_id: collection.id)).to be_empty
    expect(DocumentSet.where(collection_id: collection.id)).to be_empty
  end

  def create_collection_with_work_pages
    create(:collection, :docset_enabled, owner_user_id: owner.id, works: []).tap do |collection|
      work = create(:work, owner: owner, owner_user_id: owner.id, collection: collection)
      create(:page, work: work, position: 1, status: :transcribed, source_text: 'Not blank')
      create(:page, work: work, position: 2, status: :transcribed, source_text: 'Not blank')
      collection.works.reset
    end
  end
end
