# frozen_string_literal: true

require 'spec_helper'

describe 'Devise' do
  before do
    DatabaseCleaner.start
    ActionMailer::Base.deliveries.clear
  end

  after do
    ActionMailer::Base.deliveries.clear
    DatabaseCleaner.clean
  end

  let(:old_user) { create(:unique_user) }
  let(:old_path) { user_profile_path(old_user) }

  context 'registration' do
    let(:user) { build(:unique_user) }
    let(:owner) { build(:unique_user, :owner) }
    let(:collection_owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner: collection_owner) }
    let(:coll_path) { collection_path(collection.owner, collection) }

    it 'fails to create a new user account' do
      visit new_user_registration_path
      complete_user_registration(user, email: 'spammy@email.xyz')

      expect(page).to have_content('Email is from a domain that is not allowed for sign up')
    end

    it 'creates a new user account' do
      visit new_user_registration_path
      complete_user_registration(user)

      registered_user = User.find_by!(email: user.email)
      expect(page).to have_content("Signed In As#{registered_user.display_name}")
    end

    it 'redirects user to dashboard/watchlist after signup' do
      visit new_user_registration_path
      complete_user_registration(user)

      expect(page.current_path).to eq dashboard_watchlist_path
    end

    it 'redirects user to previous path (if present) after signup' do
      # Previous page
      visit old_path
      click_link('Sign Up To Transcribe')
      complete_user_registration(user)

      expect(page.current_path).to eq old_path
    end

    it 'logs a `joined` deed if landing page was a collection' do
      # This is the Landing Page
      visit coll_path
      # Complete user registration
      visit new_user_registration_path
      complete_user_registration(user)

      expect(page.current_path).to eq coll_path

      # Lazy loaded deeds workaround
      lazy_frame = page.find('turbo-frame#lazy_deeds')
      src = lazy_frame[:src]
      expect(src).to be_present
      registered_user = User.find_by!(email: user.email)
      joined_deed_text = "#{registered_user.display_name} joined #{collection.title}"
      visit src
      expect(ActionView::Base.full_sanitizer.sanitize(page.body)).to include(joined_deed_text)

      visit dashboard_watchlist_path
      expect(page).to have_content(joined_deed_text)
    end

    it 'creates a new trial owner account' do
      visit users_new_trial_path
      complete_trial_registration(owner)

      expect(page).to have_content("Signed In As#{owner.display_name}")
    end

    it 'redirects owner to dashboard/owner#freetrial after signup' do
      visit users_new_trial_path
      complete_trial_registration(owner)

      # This is the closest I can get to testing this path.
      # Ideally we would also test that the path includes `#freetrial`
      # but this seems to be a limitation of Capybara-Webkit
      expect(page.current_path).to eq dashboard_owner_path
    end

    it 'does not redirect owner to previous page after signup' do
      # Previous page
      visit old_path
      visit users_new_trial_path
      complete_trial_registration(owner)

      # This is the closest I can get to testing this path.
      # Ideally we would also test that the path includes `#freetrial`
      # but this seems to be a limitation of Capybara-Webkit
      expect(page.current_path).to eq dashboard_owner_path
    end

    it 'stays on trial signup form when organization name is blank' do
      visit users_new_trial_path
      complete_trial_registration(owner, organization_name: '')

      expect(page).to have_content("Organization Name can't be blank")
      expect(page).to have_content('Sign Up for a Trial')
      expect(page.current_path).to eq user_registration_path
    end
  end

  context 'user login' do
    let(:user) { create(:unique_user) }

    it 'signs in a user' do
      visit new_user_session_path
      sign_in(user)

      expect(page).to have_content(user.display_name)
      expect(page).not_to have_content('Sign In')
    end

    it 'redirects user back to original path' do
      visit old_path
      visit new_user_session_path
      sign_in(user)

      expect(page.current_path).to eq old_path
    end

    it 'redirects user back to user landing_page if no deed yet' do
      visit new_user_session_path
      sign_in(user)

      expect(page.current_path).to eq landing_page_path
    end

    context 'with deed' do
      let!(:deed) { create(:deed, user: user, deed_type: DeedType::WORK_ADDED) }

      it 'redirects user back to user dashboard/watchlist if original path was nil' do
        visit new_user_session_path
        sign_in(user)

        expect(page.current_path).to eq dashboard_watchlist_path
      end
    end
  end

  context 'owner login' do
    let(:owner) { create(:unique_user, :owner) }

    it 'signs in an owner' do
      visit new_user_session_path
      sign_in(owner)

      expect(page).to have_content(owner.display_name)
      expect(page).not_to have_content('Sign In')
    end

    it 'redirects owner back to original path' do
      visit old_path
      visit new_user_session_path
      sign_in(owner)

      expect(page.current_path).to eq old_path
    end

    it 'redirects an owner without collections to the start-project dashboard' do
      visit new_user_session_path
      sign_in(owner)

      expect(page.current_path).to eq dashboard_startproject_path
    end

    it 'redirects an owner with a collection to the owner dashboard' do
      create(:collection, owner: owner, works: [])
      visit new_user_session_path
      sign_in(owner)

      expect(page.current_path).to eq dashboard_owner_path
    end
  end

  context 'admin login' do
    let(:admin) { create(:unique_user, :admin) }

    it 'signs in an admin' do
      visit new_user_session_path
      sign_in(admin)

      expect(page).to have_content(admin.display_name)
      expect(page).not_to have_content('Sign In')
    end

    it 'redirects an admin to the admin dashboard' do
      visit new_user_session_path
      sign_in(admin)

      expect(page.current_path).to eq admin_path
    end

    it 'does not redirect an admin back to the original path' do
      visit old_path
      visit new_user_session_path
      sign_in(admin)

      expect(page.current_path).to eq admin_path
    end
  end

  def complete_user_registration(user, email: user.email)
    page.fill_in 'Username', with: user.login
    page.fill_in 'Email Address', with: email
    page.fill_in 'Password', with: user.password
    page.fill_in 'Confirm Password', with: user.password
    page.fill_in 'Real Name', with: user.display_name
    click_button('Create Account')
  end

  def complete_trial_registration(owner, organization_name: owner.display_name)
    page.fill_in 'Login', with: owner.login
    page.fill_in 'Email Address', with: owner.email
    page.fill_in 'Password', with: owner.password
    page.fill_in 'Confirm Password', with: owner.password
    page.fill_in :user_real_name, with: organization_name
    click_button('Create Account')
  end

  def sign_in(user)
    page.fill_in 'Login', with: user.login
    page.fill_in 'Password', with: user.password
    click_button('Sign In')
  end
end
