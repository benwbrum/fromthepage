require 'spec_helper'

describe 'User profile and settings actions' do
  before :each do
    @user = User.create(
      login: 'user_login',
      password: 'password',
      password_confirmation: 'password',
      email: 'test@example.com',
      display_name: 'Display Name'
    )
    @user.save
  
    visit new_user_session_path
    fill_in 'Login', with: 'user_login'
    fill_in 'Password', with: 'password'
    click_button('Sign In')
  end

  after :each do
    @user.delete
  end

  it 'should update user email and redirect to user edit page after edit' do
    edit_user_path = url_for(action: 'edit', controller: 'registrations')
    # login_as(@user, :scope => :user)
    visit edit_user_path
    expect(current_url).to eq(edit_user_path)
    # There's some problem with keeping the session and changing the username
    # in the test. It works in the real app, but I'd like to sort it out, if I can
    # fill_in('user[login]', with: 'NewLogin')
    fill_in('user[email]', with: 'newemail@example.com')
    fill_in('user[current_password]', with: 'password')
    click_button('Save Changes')
    expect(page).to have_content('You updated your account successfully')
    expect(current_url).to eq(edit_user_path)
  end

  it 'should update user Display Name' do
    click_link('Your Profile')
    expect(page.first('.headline_title').text).to eq 'Display Name'
    click_link('Edit Profile')
    expect(find_field('user[display_name]').value).to eq 'Display Name'
    fill_in('user[display_name]', with: 'New Name')
    click_button('Update Profile')
    expect(page.first('.headline_title').text).to eq 'New Name'
  end
end
