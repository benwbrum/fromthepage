# frozen_string_literal: true

require 'spec_helper'

describe 'collection legend display' do
  let(:owner) { create(:unique_user, :owner) }
  let(:legend) { '<p>This is a test legend for the collection.</p>' }
  let(:collection) { create(:collection, owner: owner, works: [], legend: legend) }
  let(:work) { create(:work, owner: owner, collection: collection) }
  let(:test_page) { create(:page, work: work, title: 'Test Page') }

  before do
    DatabaseCleaner.start
    test_page
  end

  after do
    DatabaseCleaner.clean
  end

  subject(:visit_page) do
    visit collection_display_page_path(collection.owner, collection, work, test_page.id)
  end

  context 'when the collection has a legend' do
    it 'displays the legend on the page view' do
      visit_page

      expect(page.find('.page-legend')).to have_content('Legend')
      expect(page.find('.page-legend-content')).to have_content('This is a test legend for the collection.')
    end
  end

  context 'when the collection legend is blank' do
    let(:legend) { '' }

    it 'does not display the legend section' do
      visit_page

      expect(page).not_to have_selector('.page-legend')
    end
  end
end
