require 'spec_helper'

describe "editor actions" do

  before :all do
    @user = User.find_by(login: 'hermione')
    collection_ids = Deed.where(:user_id => @user.id).select(:collection_id).distinct.limit(5).map(&:collection_id)
    @collections = Collection.where(:id => collection_ids).order_by_recent_activity
    @collection = @collections.first
    @work = @collection.works.first
    @page = @work.pages.first
    @auth = TranscribeAuthorization.find_by(user_id: @user.id)
  end

  it "signs in an editor with no activity" do
      visit new_user_session_path
      fill_in 'Login', with: 'ron'
      fill_in 'Password', with: 'password'
      click_button('Sign In')
      expect(page.current_path).to eq dashboard_watchlist_path
      expect(page).to have_content("Editor Dashboard")
      expect(page).to have_content("You haven't participated in any projects yet.")
  end

  it "signs in an editor with activity" do
      visit new_user_session_path
      fill_in 'Login', with: 'hermione'
      fill_in 'Password', with: 'password'
      click_button('Sign In')
      expect(page.current_path).to eq dashboard_watchlist_path
      expect(page).to have_content("Editor Dashboard")
      expect(page).to have_content(@collection.title)
      within "sidecol" do
        expect(page).to have_content("Your Activity")
        #list of your deeds - how to test?

      end
  end

  it "makes sure editor with permissions can see a restricted work" do
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@auth.work_id}"
    click_link @work.pages.first.title
    expect(page.find('.tabs')).to have_content("Transcribe")
  end

  it "checks that a restricted editor can't see a work" do
    @user = User.find_by(login: 'ron')
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@auth.work_id}"
    click_link @work.pages.first.title
    expect(page.find('.tabs')).not_to have_content("Transcribe")
  end


end