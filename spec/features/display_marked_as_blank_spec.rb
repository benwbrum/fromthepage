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

  it 'shows pages marked blank with a relative time in the short activity sidebar', js: true do
    visit collections_list_path

    lazy_frame = page.find('turbo-frame#lazy_deeds')
    expect(lazy_frame).to have_content("#{user.display_name} marked #{blank_page.title} as blank")
    expect(lazy_frame.find('time.timeago').text).to end_with('ago')
  end

  it 'shows pages marked blank with a relative time in the long activity sidebar', js: true do
    visit collection_path(user, collection)

    expect(page).to have_content('Recent Edits')

    lazy_frame = page.find('turbo-frame#lazy_deeds')
    expect(lazy_frame).to have_content("#{user.display_name} marked #{blank_page.title} as blank")
    expect(lazy_frame.find('time.timeago').text).to end_with('ago')
  end
end
