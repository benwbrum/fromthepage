require 'spec_helper'


describe "different user role logins" do

  before :all do
    @collections = Collection.all
    @collection = @collections.last
    @password = 'password'
  end

  it "tests guest dashboard" do
    visit root_path
    click_link('Dashboard')
    expect(page.current_path).to eq guest_dashboard_path
    expect(page).to have_content("Sign In")
    expect(page).not_to have_content("Signed In As")
    click_link('Collections')
    @collections.each do |c|
      expect(page).to have_content(c.title)
    end
    page.find('h4', text: @collection.title).click_link(@collection.title)
    @collection.works.each do |w|
      expect(page).to have_content(w.title)
    end
  end

  it "signs in an editor with no activity" do
      visit new_user_session_path
      fill_in 'Login', with: REST_USER
      fill_in 'Password', with: @password
      click_button('Sign In')
      expect(page.current_path).to eq dashboard_watchlist_path
      expect(page).to have_content("Collaborator Dashboard")
      expect(page).to have_content("You haven't participated in any projects yet.")
      visit root_path
      click_link('Dashboard')
      expect(page.current_path).to eq dashboard_watchlist_path
  end

  it "signs in an editor with activity" do
    #find user activity
    user = User.find_by(login: USER)
    collection_ids = Deed.where(:user_id => user.id).select(:collection_id).distinct.limit(5).map(&:collection_id)
    collections = Collection.where(:id => collection_ids).order_by_recent_activity
    #check sign in with editor permissions
    visit new_user_session_path
    fill_in 'Login', with: USER
    fill_in 'Password', with: @password
    click_button('Sign In')
    expect(page.current_path).to eq dashboard_watchlist_path
    expect(page).to have_content("Collaborator Dashboard")
    expect(page).to have_content(collections.first.title)
    within ".sidecol" do
      expect(page).to have_content("Your Activity")
    end
    visit root_path
    click_link('Dashboard')
    expect(page.current_path).to eq dashboard_watchlist_path
    #make sure user doesn't have admin access
    expect(page).to have_selector('a', text: 'Collaborator Dashboard')
    expect(page).not_to have_selector('a', text: 'Owner Dashboard')
    expect(page).not_to have_selector('a', text: 'Admin Dashboard')

  end

  it "signs an owner in" do
    user = User.find_by(login: OWNER)
    @collections = user.all_owner_collections
    
    visit new_user_session_path
    fill_in 'Login', with: OWNER
    fill_in 'Password', with: @password
    click_button('Sign In')
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).to have_content("Owner Dashboard")
    @collections.each do |c|
      expect(page).to have_content(c.title)
      c.works.each do |w|
        expect(page).to have_content(w.title)
      end
    end
    visit root_path
    click_link('Dashboard')
    expect(page.current_path).to eq dashboard_owner_path
    #check for owner but not admin dashboard
    expect(page).to have_selector('a', text: 'Owner Dashboard')
    expect(page).not_to have_selector('a', text: 'Admin Dashboard')
  end

  it "signs an admin in" do
    #check sign in with admin permissions  
    visit new_user_session_path
    fill_in 'Login', with: ADMIN
    fill_in 'Password', with: @password
    click_button 'Sign In'
    expect(page.current_path).to eq admin_path
    expect(page).to have_content("Administration")
    visit root_path
    click_link('Dashboard')
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).to have_selector('a', text: 'Admin Dashboard')
  end

end