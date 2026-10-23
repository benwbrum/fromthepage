# frozen_string_literal: true

require 'spec_helper'

describe 'Pages need indexing' do
  INDEXING_BUTTON_TEXT = 'Pages That Need Indexing'

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end

  let(:collection) { create(:collection, :with_pages, subjects_disabled: subjects_disabled) }
  let(:work) { collection.works.first }
  let(:page_status) { nil }

  before do
    work.pages.first.update!(status: page_status) if page_status

    visit "/#{collection.owner.login}/#{collection.slug}"
    expect(page).to have_text(collection.title)

    page.find('.collection-work_title', text: work.title).click_link(work.title)
  end

  context 'when a collection has indexing disabled' do
    let(:subjects_disabled) { true }

    it 'does not show the indexing button' do
      expect(page).not_to have_button(INDEXING_BUTTON_TEXT)
    end
  end

  context 'when a collection has indexing enabled' do
    let(:subjects_disabled) { false }
    let(:page_status) { 'indexed' }

    it 'does not show the indexing button when the page is already indexed' do
      expect(page).not_to have_button(INDEXING_BUTTON_TEXT)
    end
  end
end
