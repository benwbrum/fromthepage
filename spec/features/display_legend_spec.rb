require 'spec_helper'

describe "collection legend display" do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, owner_user_id: user.id, legend: '<p>This is a test legend for the collection.</p>') }
  let(:work) { create(:work, owner_user_id: user.id, collection_id: collection.id) }
  let(:test_page) { create(:page, work_id: work.id, title: 'Test Page') }

  it 'displays legend on page view when legend is present' do
    # Visit the display page
    visit collection_display_page_path(collection.owner, collection, work, test_page.id)

    expect(page).to have_content('Legend')
    expect(page).to have_content('This is a test legend for the collection.')
  end

  it 'does not display legend section when legend is blank' do
    # Create collection without legend
    collection_without_legend = create(:collection, owner_user_id: user.id, legend: '')
    work_without_legend = create(:work, owner_user_id: user.id, collection_id: collection_without_legend.id)
    test_page_without_legend = create(:page, work_id: work_without_legend.id, title: 'Test Page With No Explanation')

    # Visit the display page
    visit collection_display_page_path(collection_without_legend.owner, collection_without_legend, work_without_legend, test_page_without_legend.id)

    expect(page).not_to have_content('Legend')
  end
end
