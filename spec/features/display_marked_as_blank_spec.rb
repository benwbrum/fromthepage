# frozen_string_literal: true

require 'spec_helper'

describe 'display marked as blank' do
  let(:user) { create(:unique_user) }
  let(:collection) { create(:collection, owner_user_id: user.id, works: []) }
  let(:work) { create(:work, owner: user, collection: collection) }
  let(:blank_page) { create(:page, work: work, status: :blank) }
  let(:deed) do
    create(
      :deed,
      deed_type: DeedType::PAGE_MARKED_BLANK,
      page_id: blank_page.id,
      work: work,
      collection: collection,
      user: user
    )
  end

  before do
    DatabaseCleaner.start
    deed
  end

  after do
    DatabaseCleaner.clean
  end

  it 'shows pages marked blank on the main activity feed page' do
    visit deed_list_path(collection_id: collection.slug)

    expect(page).to have_content('Page Marked Blank')
  end

  it 'shows pages marked blank in the collections activity sidebar' do
    visit collections_list_path

    expect(page.find('.sidecol')).to have_content(
      "#{user.display_name} marked #{blank_page.title} as blank"
    )
  end

  it 'shows pages marked blank in the collection recent-edits sidebar' do
    visit collection_path(user, collection)

    expect(page).to have_content('Recent Edits')
    expect(page.find('.sidecol')).to have_content(
      "#{user.display_name} marked #{blank_page.title} as blank"
    )
  end
end
