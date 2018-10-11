require 'spec_helper'

describe "Pages need indexing" do
  INDEXING_BUTTON_TEXT = 'Pages That Need Indexing'
  REVIEW_BUTTON_TEXT = 'Pages That Need Review'

  scenario "when a collection has indexing disabled" do
    visit "/collections"
    expect(page).to have_text("Collections")

    collection = Collection.first
    original_subject_state = collection.subjects_disabled

    # Disable Subject Indexing
    collection.subjects_disabled = true
    collection.save

    find('.maincol').find_link(collection.title).click
    find('.maincol').find_link(collection.works.first.title).click

    expect(page).to have_button(REVIEW_BUTTON_TEXT)
    expect(page).to_not have_button(INDEXING_BUTTON_TEXT)

    # Reset Modified Fixtures
    collection.subjects_disabled = original_subject_state
    collection.save
  end

  scenario "when a collection has indexing enabled" do
    visit "/collections"
    expect(page).to have_text("Collections")

    collection = Collection.first
    original_subject_state = collection.subjects_disabled

    # Enable Subject Indexing
    collection.subjects_disabled = false
    collection.save

    find('.maincol').find_link(collection.title).click
    find('.maincol').find_link(collection.works.first.title).click

    expect(page).to have_button(INDEXING_BUTTON_TEXT)

    # Reset Modified Fixtures
    collection.subjects_disabled = original_subject_state
    collection.save
  end
end
