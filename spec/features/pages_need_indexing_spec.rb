require 'spec_helper'

describe "Pages need indexing" do
  INDEXING_BUTTON_TEXT = 'Pages That Need Indexing'

  it 'when a collection has indexing disabled' do
    collection = create(:collection, :with_pages, subjects_disabled: true)

    visit "/#{collection.owner.login}/#{collection.slug}"
    expect(page).to have_text(collection.title)

    page.find('.collection-work_title', text: collection.works.first.title).click_link collection.works.first.title
    expect(page).to_not have_button(INDEXING_BUTTON_TEXT)

    # Remove Factories
    user_id = collection.owner.id
    collection_id = collection.id
    Collection.destroy(collection_id)
    User.destroy(user_id)
  end

  it 'when a collection has indexing enabled' do
    collection = create(:collection, :with_pages, subjects_disabled: false)
    collection_page = collection.works.first.pages.first
    original_page_status = collection_page.status
    collection_page.update!(status: 'indexed')

    visit "/#{collection.owner.login}/#{collection.slug}"
    expect(page).to have_text(collection.title)

    page.find('.collection-work_title', text: collection.works.first.title).click_link collection.works.first.title
    expect(page).not_to have_button(INDEXING_BUTTON_TEXT)
    collection_page.update!(status: original_page_status)

    # Remove Factories
    user_id = collection.owner.id
    collection_id = collection.id
    Collection.destroy(collection_id)
    User.destroy(user_id)
  end
end
