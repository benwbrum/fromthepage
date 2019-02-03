require 'spec_helper'

describe "display marked as blank" do
  let(:deed_type) { DeedType::PAGE_MARKED_BLANK }

  it 'shows pages marked blank in main Activity Feed page' do
    # Build out factories
    user = create(:user)
    collection = create(:collection, owner_user_id: user.id)
    work = create(:work, owner_user_id: user.id, collection_id: collection.id)
    page1 = create(:page, work_id: work.id)
    deed = create(:deed, {
      deed_type: deed_type,
      page_id: page1.id,
      work_id: work.id,
      collection_id: collection.id,
      user_id: user.id
      })

    # Visit page
    visit 'deed/list'
    expect(page).to have_content('Page Marked Blank')

    # Tear down Factories
    Deed.destroy(deed.id)
    Page.destroy(page1.id)
    Work.destroy(work.id)
    Collection.destroy(collection.id)
    User.destroy(user.id)
  end

  it 'shows pages marked blank in collection Recent Activity sidebar feed' do
    # Build out factories
    user = create(:user)
    collection = create(:collection, owner_user_id: user.id)
    work = create(:work, owner_user_id: user.id, collection_id: collection.id)
    page1 = create(:page, work_id: work.id)
    deed = create(:deed, {
      deed_type: deed_type,
      page_id: page1.id,
      work_id: work.id,
      collection_id: collection.id,
      user_id: user.id
      })

    # Visit page
    visit 'collections'
    expect(page.find('.sidecol')).to have_content("#{user.display_name} marked page #{page1.title} as blank")

    # Tear down Factories
    Deed.destroy(deed.id)
    Page.destroy(page1.id)
    Work.destroy(work.id)
    Collection.destroy(collection.id)
    User.destroy(user.id)
  end

  it 'shows pages marked blank in collection Recent Edits sidebar feed' do
    # Build out factories
    user = create(:user)
    collection = create(:collection, owner_user_id: user.id)
    work = create(:work, owner_user_id: user.id, collection_id: collection.id)
    page1 = create(:page, work_id: work.id)
    deed = create(:deed, {
      deed_type: deed_type,
      page_id: page1.id,
      work_id: work.id,
      collection_id: collection.id,
      user_id: user.id
      })

    # Visit page
    visit "#{user.login}/#{collection.slug}"
    expect(page).to have_content('Recent Edits')
    expect(page.find('.sidecol')).to have_content("#{user.display_name} marked page #{page1.title} as blank")

    # Tear down Factories
    Deed.destroy(deed.id)
    Page.destroy(page1.id)
    Work.destroy(work.id)
    Collection.destroy(collection.id)
    User.destroy(user.id)
  end
end
