# frozen_string_literal: true

require 'spec_helper'

describe "different user role logins" do
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end

  let(:inactive_user)    { create(:unique_user) }
  let(:regular_user)     { create(:unique_user) }
  let(:activity_collection) { create(:collection) }
  let(:email_user)       { create(:unique_user) }
  let(:owner_user)       { create(:owner) }
  let!(:owner_collection) { create(:collection, owner_user_id: owner_user.id) }
  let(:admin_user)       { create(:unique_user, :admin, :owner) }
  let!(:admin_collection) { create(:collection, owner_user_id: admin_user.id) }

  it "creates a new user account" do
    new_login = "test_#{SecureRandom.hex(6)}"
    new_email = "#{new_login}@test.com"
    user_count = User.all.count
    visit root_path
    expect(page).to have_link("Sign In")
    expect(page).not_to have_link(I18n.t('dashboard.plain'))
    first(:link, 'Sign In').click
    expect(page).to have_link("Sign Up Now")
    click_link("Sign Up Now")
    expect(page.current_path).to eq new_user_registration_path
    click_button('Create Account')
    expect(page).to have_content('3 errors prohibited the user from being saved')
    page.fill_in 'Username', with: new_login
    page.fill_in 'Email Address', with: new_email
    page.fill_in 'Password', with: 'password'
    page.fill_in 'Confirm Password', with: 'password'
    page.fill_in 'Real Name', with: 'Alexander'
    click_button('Create Account')
    new_user_count = User.all.count
    expect(page.current_path).to eq dashboard_watchlist_path
    expect(new_user_count).to eq (user_count + 1)
  end

  it 'signs in an editor with no activity' do
    visit new_user_session_path
    fill_in 'Login', with: inactive_user.login
    fill_in 'Password', with: 'password'
    click_button('Sign In')
    expect(page.current_path).to eq landing_page_path
  end

  it "signs in an editor with activity" do
    # note: signs in with login id
    # find user activity
    work = activity_collection.works.first
    create(:deed, user: regular_user, collection: activity_collection, work: work)
    collection_ids = Deed.where(user_id: regular_user.id).select(:collection_id).distinct.limit(5).map(&:collection_id)
    collections = Collection.where(id: collection_ids).order_by_recent_activity
    # check sign in with editor permissions
    visit new_user_session_path
    fill_in 'Login', with: regular_user.login
    fill_in 'Password', with: 'password'
    click_button('Sign In')
    expect(page.current_path).to eq dashboard_watchlist_path
    expect(page).to have_content(I18n.t('dashboard.collaborator'))
    expect(page).to have_content(collections.first.title)
    within ".sidecol" do
      expect(page).to have_content("Your Activity")
    end
    visit root_path
    click_link('Dashboard')
    expect(page.current_path).to eq dashboard_watchlist_path
    # make sure user doesn't have admin access
    expect(page).to have_selector('a', text: I18n.t('dashboard.collaborator'))
    expect(page).not_to have_selector('a', text: 'Owner Dashboard')
    expect(page).not_to have_selector('a', text: 'Admin Dashboard')
  end

  it "signs a user in with email address" do
    work = activity_collection.works.first
    create(:deed, user: email_user, collection: activity_collection, work: work)
    visit new_user_session_path
    fill_in 'Login', with: email_user.email
    fill_in 'Password', with: 'password'
    click_button('Sign In')
    expect(page.current_path).to eq dashboard_watchlist_path
    expect(page).to have_content(I18n.t('dashboard.collaborator'))
  end

  it "signs an owner in" do
    collections = owner_user.reload.all_owner_collections
    sets = owner_user.document_sets
    visit new_user_session_path
    fill_in 'Login', with: owner_user.login
    fill_in 'Password', with: 'password'
    click_button('Sign In')
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).to have_content("Owner Dashboard")
    collections.each do |c|
      expect(page).to have_content(c.title)
      expect(page).to have_content("#{c.works.count} works")
    end
    sets.each do |s|
      expect(page).to have_content(s.title)
    end
    visit root_path
    click_link(I18n.t('dashboard.plain'))
    expect(page.current_path).to eq dashboard_owner_path
    # check for owner but not admin dashboard
    expect(page).to have_selector('a', text: 'Owner Dashboard')
    expect(page).not_to have_selector('a', text: 'Admin Dashboard')
  end

  it "signs an admin in" do
    # check sign in with admin permissions
    visit new_user_session_path
    fill_in 'Login', with: admin_user.login
    fill_in 'Password', with: 'password'
    click_button 'Sign In'
    expect(page.current_path).to eq admin_path
    expect(page).to have_content("Administration")
    visit root_path
    click_link('Dashboard')
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).to have_selector('a', text: 'Admin Dashboard')
  end
end
