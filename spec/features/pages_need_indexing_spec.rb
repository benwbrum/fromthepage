require 'spec_helper'

describe "Pages need indexing" do
  INDEXING_BUTTON_TEXT = 'Pages That Need Indexing'
  REVIEW_BUTTON_TEXT = 'Pages That Need Review'

  scenario "when a collection has indexing disabled" do
    collection = create(:collection, :with_pages, subjects_disabled: true)

    visit "/#{collection.owner.login}/#{collection.slug}"
    expect(page).to have_text(collection.title)

    find('.maincol').find_link(collection.works.first.title).click
    expect(page).to have_button(REVIEW_BUTTON_TEXT)
    expect(page).to_not have_button(INDEXING_BUTTON_TEXT)

    # Remove Factories
    user_id = collection.owner.id
    collection_id = collection.id
    Collection.destroy(collection_id)
    User.destroy(user_id)
  end

  scenario "when a collection has indexing enabled" do
    collection = create(:collection, :with_pages, subjects_disabled: false)

    visit "/#{collection.owner.login}/#{collection.slug}"
    expect(page).to have_text(collection.title)

    find('.maincol').find_link(collection.works.first.title).click
    expect(page).to have_button(REVIEW_BUTTON_TEXT)
    expect(page).to have_button(INDEXING_BUTTON_TEXT)

    # Remove Factories
    user_id = collection.owner.id
    collection_id = collection.id
    Collection.destroy(collection_id)
    User.destroy(user_id)
  end
end
