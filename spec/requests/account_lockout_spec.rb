require 'spec_helper'

describe 'Account lockout and password length' do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { create(:unique_user) }
  let(:admin) { create(:unique_user, admin: true) }

  after do
    travel_back
  end

  def sign_in_with(password)
    post user_session_path, params: { user: { login_id: user.login, password: password } }
  end

  it 'locks for 30 minutes after 5 failed attempts' do
    expect(User.maximum_attempts).to eq(5)
    expect(User.unlock_in).to eq(30.minutes)
    expect(User.unlock_strategy).to eq(:time)
  end

  it 'locks the account after 5 consecutive failed sign-ins' do
    4.times { sign_in_with('wrong-password') }
    expect(user.reload.access_locked?).to be(false)

    sign_in_with('wrong-password')
    expect(user.reload.access_locked?).to be(true)

    sign_in_with('password')
    expect(response.body).to include(CGI.escapeHTML(I18n.t('devise.failure.locked')))
    expect(controller.current_user).to be_nil
  end

  it 'unlocks automatically after 30 minutes' do
    5.times { sign_in_with('wrong-password') }
    expect(user.reload.access_locked?).to be(true)

    travel 31.minutes
    sign_in_with('password')
    expect(controller.current_user).to eq(user)
  end

  it 'lets an admin unlock a locked account' do
    user.lock_access!
    login_as admin

    get admin_unlock_user_path(user_id: user.id)
    expect(user.reload.access_locked?).to be(false)
  end

  it 'does not let an admin log in as a locked user' do
    user.lock_access!
    login_as admin

    get user_masquerade_path(user)
    expect(response).to redirect_to(admin_user_list_path)

    get dashboard_path
    expect(controller.current_user).to eq(admin)
  end

  it 'requires new passwords to be at least 8 characters' do
    user.password = user.password_confirmation = 'short77'
    expect(user).not_to be_valid

    user.password = user.password_confirmation = 'longer88'
    expect(user).to be_valid
  end

  it 'still lets existing users sign in with shorter passwords' do
    # Set a 6-character password directly, as if it predated the 8-character minimum
    legacy = User.new(password: 'abc123')
    user.update_columns(encrypted_password: legacy.encrypted_password, password_salt: legacy.password_salt)

    sign_in_with('abc123')
    expect(controller.current_user).to eq(user)
  end
end
