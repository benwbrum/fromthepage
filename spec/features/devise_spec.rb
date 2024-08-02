require 'spec_helper'

describe "Devise" do
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
  end

  let(:old_user){ create(:user) }
  let(:old_path){ user_profile_path(old_user) }

  context "registration" do

    let(:user)  { build(:user) }
    let(:owner) { build(:owner) }
    let(:collection) { create(:collection) }
    let(:coll_path){ collection_path(collection.owner, collection) }

    it "creates a new user account" do
      visit new_user_registration_path
      page.fill_in 'Username', with: user.login
      page.fill_in 'Email Address', with: user.email
      page.fill_in 'Password', with: user.password
      page.fill_in 'Confirm Password', with: user.password
      page.fill_in 'Real Name', with: user.display_name
      click_button('Create Account')
      expect(page).to have_content("Signed In As#{user.display_name}")
    end
    it "redirects user to dashboard/watchlist after signup" do
      visit new_user_registration_path
      page.fill_in 'Username', with: user.login
      page.fill_in 'Email Address', with: user.email
      page.fill_in 'Password', with: user.password
      page.fill_in 'Confirm Password', with: user.password
      page.fill_in 'Real Name', with: user.display_name
      click_button('Create Account')
      expect(page.current_path).to eq dashboard_watchlist_path
    end
    it "redirects user to previous path (if present) after signup" do
      # Previous page
      visit old_path
      click_link('Sign Up To Transcribe')
#      visit new_user_registration_path
      page.fill_in 'Username', with: user.login
      page.fill_in 'Email Address', with: user.email
      page.fill_in 'Password', with: user.password
      page.fill_in 'Confirm Password', with: user.password
      page.fill_in 'Real Name', with: user.display_name
      click_button('Create Account')
      expect(page.current_path).to eq old_path
    end
    it "logs a `joined` deed if landing page was a collection" do
      # This is the Landing Page
      visit coll_path
      # Complete user registration
      visit new_user_registration_path
      page.fill_in 'Username', with: user.login
      page.fill_in 'Email Address', with: user.email
      page.fill_in 'Password', with: user.password
      page.fill_in 'Confirm Password', with: user.password
      page.fill_in 'Real Name', with: user.display_name
      click_button('Create Account')

      expect(page.current_path).to eq coll_path
      expect(page).to have_content("#{user.display_name} joined #{collection.title}")

      visit dashboard_watchlist_path
      expect(page).to have_content("#{user.display_name} joined #{collection.title}")
    end
    it "creates a new trial owner account" do
      visit users_new_trial_path
      page.fill_in 'Login', with: owner.login
      page.fill_in 'Email Address', with: owner.email
      page.fill_in 'Password', with: owner.password
      page.fill_in 'Confirm Password', with: owner.password
      page.fill_in :user_real_name, with: owner.display_name
      click_button('Create Account')
      expect(page).to have_content("Signed In As#{owner.display_name}")
    end
    it "redirects owner to dashboard/owner#freetrial after signup" do
      visit users_new_trial_path
      page.fill_in 'Login', with: owner.login
      page.fill_in 'Email Address', with: owner.email
      page.fill_in 'Password', with: owner.password
      page.fill_in 'Confirm Password', with: owner.password
      page.fill_in :user_real_name, with: owner.display_name
      click_button('Create Account')
      # This is the closest I can get to testing this path.
      # Ideally we would also test that the path includes `#freetrial`
      # but this seems to be a limitation of Capybara-Webkit
      expect(page.current_path).to eq dashboard_owner_path
    end
    it "does not redirect owner to previous page after signup" do
      # Previous page
      visit old_path
      visit users_new_trial_path
      page.fill_in 'Login', with: owner.login
      page.fill_in 'Email Address', with: owner.email
      page.fill_in 'Password', with: owner.password
      page.fill_in 'Confirm Password', with: owner.password
      page.fill_in :user_real_name, with: owner.display_name
      click_button('Create Account')
      # This is the closest I can get to testing this path.
      # Ideally we would also test that the path includes `#freetrial`
      # but this seems to be a limitation of Capybara-Webkit
      expect(page.current_path).to eq dashboard_owner_path
    end
  end

  context "user login" do
    let(:user){ create(:user) }
    it "signs in a user" do
      visit new_user_session_path
      page.fill_in 'Login', with: user.login
      page.fill_in 'Password', with: user.password
      click_button('Sign In')
      expect(page).to have_content(user.display_name)
      expect(page).to_not have_content("Sign In")
    end
    it "redirects user back to original path" do
      visit old_path
      visit new_user_session_path
      page.fill_in 'Login', with: user.login
      page.fill_in 'Password', with: user.password
      click_button('Sign In')
      expect(page.current_path).to eq old_path
    end
    it "redirects user back to user dashboard/watchlist if original path was nil" do
      visit new_user_session_path
      page.fill_in 'Login', with: user.login
      page.fill_in 'Password', with: user.password
      click_button('Sign In')
      expect(page.current_path).to eq dashboard_watchlist_path
    end
  end
  context "owner login" do
    let(:owner){ create(:owner) }
    it "signs in an owner" do
      visit new_user_session_path
      page.fill_in 'Login', with: owner.login
      page.fill_in 'Password', with: owner.password
      click_button('Sign In')
      expect(page).to have_content(owner.display_name)
      expect(page).to_not have_content("Sign In")
    end
    it "redirects owner back to original path" do
      visit old_path
      visit new_user_session_path
      page.fill_in 'Login', with: owner.login
      page.fill_in 'Password', with: owner.password
      click_button('Sign In')
      expect(page.current_path).to eq old_path
    end
    it "redirects owner back to user dashboard/watchlist if original path was nil and user has no collection" do
      visit new_user_session_path
      page.fill_in 'Login', with: owner.login
      page.fill_in 'Password', with: owner.password
      click_button('Sign In')
      expect(page.current_path).to eq dashboard_startproject_path
    end
    it "redirects owner back to user dashboard/watchlist if original path was nil and user has collection" do
      _collection = create(:collection, owner_user_id: owner.id)
      visit new_user_session_path
      page.fill_in 'Login', with: owner.login
      page.fill_in 'Password', with: owner.password
      click_button('Sign In')
      expect(page.current_path).to eq dashboard_owner_path
    end
  end
  context "admin login" do
    let(:admin){ create(:admin) }
    it "signs in an admin" do
      visit new_user_session_path
      page.fill_in 'Login', with: admin.login
      page.fill_in 'Password', with: admin.password
      click_button('Sign In')
      expect(page).to have_content(admin.display_name)
      expect(page).to_not have_content("Sign In")
    end
    it "redirect admin to admin dashboard" do
      visit new_user_session_path
      page.fill_in 'Login', with: admin.login
      page.fill_in 'Password', with: admin.password
      click_button('Sign In')
      expect(page.current_path).to eq admin_path
    end
    it "does not redirect admin back to original path" do
      visit old_path
      visit new_user_session_path
      page.fill_in 'Login', with: admin.login
      page.fill_in 'Password', with: admin.password
      click_button('Sign In')
      expect(page.current_path).to eq admin_path
    end
  end

end
