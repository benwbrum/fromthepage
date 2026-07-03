# frozen_string_literal: true

require 'spec_helper'

describe 'deed list' do
  let(:owner) { create(:unique_user, :owner) }
  let(:contributor) { create(:unique_user) }
  let(:restricted) { false }
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      works: [],
      restricted: restricted
    )
  end
  let(:work) { create(:work, owner: owner, collection: collection) }
  let(:work_page) { create(:page, work: work, title: 'Deed List Test Page') }
  let(:deed) do
    create(
      :deed,
      deed_type: DeedType::PAGE_TRANSCRIPTION,
      user: contributor,
      collection: collection,
      work: work,
      page: work_page
    )
  end

  before do
    DatabaseCleaner.start
    deed
  end

  after do
    DatabaseCleaner.clean
  end

  it 'displays deeds for a public collection' do
    visit deed_list_path(collection_id: collection.slug)

    expect(page).to have_selector('h1', text: 'Activity Stream')
    expect(page).to have_selector('h3', text: "Collection: #{collection.title}")
    within '#deeds-list' do
      expect(page).to have_content(contributor.display_name)
      expect(page).to have_content(work_page.title)
      expect(page).to have_content(work.title)
    end
  end

  context 'when the collection is private' do
    let(:restricted) { true }

    it 'hides its deeds from visitors' do
      visit deed_list_path(collection_id: collection.slug)

      expect(page.current_path).to eq(user_profile_path(owner))
      expect(page).not_to have_selector('#deeds-list')
      expect(page).not_to have_content(work_page.title)
    end

    it 'displays its deeds to the collection owner' do
      login_as(owner, scope: :user)
      visit deed_list_path(collection_id: collection.slug)

      expect(page).to have_selector('#deeds-list')
      within '#deeds-list' do
        expect(page).to have_content(contributor.display_name)
        expect(page).to have_content(work_page.title)
        expect(page).to have_content(work.title)
      end
    end
  end
end
