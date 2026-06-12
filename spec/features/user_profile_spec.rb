require 'spec_helper'

describe 'User profile and settings actions' do
  let!(:user) { create(:unique_user) }

  before :each do
    login_as(user, scope: :user)
  end

  it 'should update user email and redirect to user edit page after edit' do
    edit_user_path = url_for(action: 'edit', controller: 'registrations')
    visit edit_user_path
    expect(current_url).to eq(edit_user_path)
    fill_in('user[email]', with: 'newemail@example.com')
    click_button('Save Changes')

    expect(page).to have_content('has been updated')
  end

  it 'should display number of contributions on profile page' do
    visit user_profile_path(user)
    expect(page).to have_content(user.display_name)
    expect(page).to have_content('Contributions')
  end
end
