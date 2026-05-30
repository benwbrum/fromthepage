require 'spec_helper'

describe 'URL tests' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:work_page) { create(:page, work: work) }

  # Give the user a deed so they appear on the watchlist
  let!(:deed) do
    create(:deed,
           collection: collection,
           work: work,
           page: work_page,
           user: user,
           deed_type: DeedType::PAGE_TRANSCRIPTION)
  end

  it 'visits old URLs' do
    visit "/collection/show?collection_id=#{collection.id}"
    expect(page).to have_selector('h1', text: collection.title)
    expect(page).to have_content(work.title)
    visit "/display/read_work?work_id=#{work.id}"
    expect(page).to have_selector('a', text: collection.title)
    expect(page).to have_selector('h1', text: work.title)
  end

  it 'checks URL paths/breadcrumbs' do
    login_as(user, scope: :user)
    visit dashboard_watchlist_path
    page.find('h4', text: collection.title).click_link(collection.title)
    expect(page.current_path).to eq "/#{owner.slug}/#{collection.slug}"
    page.find('.collection-work_title', text: work.title).click_link
    expect(page.current_path).to eq "/#{owner.slug}/#{collection.slug}/#{work.slug}"
    # check breadcrumb
    expect(page).to have_selector('a', text: collection.title)
    page.find('a', text: work_page.title).click
    expect(page).to have_selector('a', text: collection.title)
    expect(page).to have_selector('a', text: work.title)
    click_link(work.title)
    expect(page.current_path).to eq "/#{owner.slug}/#{collection.slug}/#{work.slug}"
    click_link collection.title
    expect(page.current_path).to eq "/#{owner.slug}/#{collection.slug}"
  end

  it 'checks user URLs' do
    login_as(user, scope: :user)
    # look at the owner profile — owners show their collections, not recent activity
    visit "/#{owner.slug}"
    owner.all_owner_collections.each do |c|
      expect(page).to have_content(c.title)
    end
    expect(page).not_to have_content("Recent Activity by #{owner.display_name}")
    # look at a user (non-owner) profile — shows recent activity, no carousel
    visit "/#{user.slug}"
    expect(page).to have_content(user.display_name)
    expect(page).not_to have_selector('.carousel')
    expect(page).to have_content("Recent Activity by #{user.display_name}")
    # make sure links go to user profile
    visit dashboard_watchlist_path
    click_link(owner.display_name, match: :first)
    expect(page.current_path).to eq "/#{owner.slug}"
    expect(page).to have_content('Projects')
    owner.all_owner_collections.each do |c|
      expect(page).to have_content(c.title)
    end
  end

  it 'edits a collection slug', js: true do
    login_as(owner, scope: :user)
    original_slug = collection.slug
    new_slug = "new-#{original_slug}"
    visit "/#{owner.slug}/#{original_slug}"
    expect(page).to have_selector('h1', text: collection.title)
    expect(page).to have_content(work.title)
    # edit the slug
    page.find('.tabs').click_link('Settings')
    expect(page).to have_field('collection[slug]', with: original_slug)
    page.fill_in 'collection_slug', with: new_slug
    page.find('h1', text: collection.title).click
    sleep(1)
    expect(page).to have_selector('h1', text: collection.title)
    expect(page).to have_content('Title')
    expect(Collection.find_by(id: collection.id).slug).to eq new_slug
    # test new path
    visit "/#{owner.slug}/#{new_slug}"
    expect(page).to have_selector('h1', text: collection.title)
    expect(page).to have_content(work.title)
    # test old path (original_slug is captured before mutation)
    visit dashboard_owner_path
    visit "/#{owner.slug}/#{original_slug}"
    expect(page).to have_selector('h1', text: collection.title)
    expect(page).to have_content(work.title)
    # blank out the slug and make sure the original is restored
    visit "/#{owner.slug}/#{original_slug}"
    page.find('.tabs').click_link('Settings')
    page.fill_in 'collection_slug', with: ''
    sleep 0.5
    expect(page).to have_selector('h1', text: collection.title)
    expect(Collection.find_by(id: collection.id).slug).to eq original_slug
  end

  it 'edits a work slug', js: true do
    login_as(owner, scope: :user)
    original_slug = work.slug
    new_slug = "new-#{original_slug}"
    # check that path works
    visit "/#{owner.slug}/#{collection.slug}/#{original_slug}"
    expect(page).to have_selector('a', text: collection.title)
    expect(page).to have_selector('h1', text: work.title)
    # edit slug
    page.find('.tabs').click_link('Settings')
    expect(page).to have_field('work[slug]', with: original_slug)
    page.fill_in 'work_slug', with: new_slug
    page.find('#work_slug').send_keys(:tab)
    expect(page).to have_content('Work updated successfully')
    expect(page).to have_selector('h1', text: work.title)
    expect(page).to have_content('Work title')
    expect(Work.find_by(id: work.id).slug).to eq new_slug
    # test new path
    visit "/#{owner.slug}/#{collection.slug}/#{new_slug}"
    expect(page).to have_selector('a', text: collection.title)
    expect(page).to have_selector('h1', text: work.title)
    # test old path (original_slug is captured before mutation)
    visit dashboard_owner_path
    visit "/#{owner.slug}/#{collection.slug}/#{original_slug}"
    expect(page).to have_selector('a', text: collection.title)
    expect(page).to have_selector('h1', text: work.title)
    # blank out work slug
    visit "/#{owner.slug}/#{collection.slug}/#{original_slug}"
    expect(page).to have_selector('a', text: collection.title)
    page.find('.tabs').click_link('Settings')
    page.fill_in 'work_slug', with: ''
    page.find('#work_slug').send_keys(:tab)
    expect(page).to have_content('Work updated successfully')
    expect(Work.find_by(id: work.id).slug).to eq original_slug
  end

  it 'edits a user slug' do
    login_as(owner, scope: :user)
    original_slug = owner.slug
    new_slug = "new-#{original_slug}"
    visit dashboard_watchlist_path
    page.find('a', text: 'Your Profile').click
    # check original path
    expect(page.current_path).to eq "/#{original_slug}"
    expect(page).to have_content(owner.display_name)
    page.find('a', text: 'Edit Profile').click
    expect(page).to have_content('Update User Profile')
    expect(page).to have_field('user[slug]', with: original_slug)
    page.fill_in 'user_slug', with: new_slug
    click_button('Update Profile')
    expect(page).to have_content(owner.display_name)
    expect(User.find_by(id: owner.id).slug).to eq new_slug
    # test new path
    visit "/#{new_slug}"
    expect(page).to have_content(owner.display_name)
    # test that user profile still works
    visit "/#{user.slug}"
    expect(page).to have_content(user.display_name)
    # blank out user slug
    visit dashboard_watchlist_path
    page.find('a', text: 'Your Profile').click
    page.find('a', text: 'Edit Profile').click
    expect(page).to have_content('Update User Profile')
    page.fill_in 'user_slug', with: ''
    click_button('Update Profile')
    expect(User.find_by(id: owner.id).slug).to eq original_slug
  end
end
