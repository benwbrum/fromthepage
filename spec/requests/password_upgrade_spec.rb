require 'spec_helper'

# SEC-06: signing in with a legacy SHA-1 hash works, upgrades it to bcrypt, and logs nobody out.
describe 'Signing in with a legacy password hash' do
  let(:password) { 'legacy password' }
  let(:salt) { Devise.friendly_token[0, 20] }
  let(:user) do
    create(:unique_user).tap do |user|
      user.update_columns(encrypted_password: User.legacy_sha1_digest(password, salt), password_salt: salt)
    end
  end

  def sign_in_with(session, login, secret)
    session.post user_session_path, params: { user: { login_id: login, password: secret } }
  end

  # The account page needs a signed-in user; otherwise it redirects to sign in.
  def signed_in?(session)
    session.get edit_user_registration_path
    session.response.status == 200
  end

  it 'signs the user in and upgrades the hash to bcrypt' do
    sign_in_with(self, user.login, password)

    expect(response).to have_http_status(:redirect)
    expect(response.location).not_to include(new_user_session_path)
    expect(user.reload.encrypted_password).to start_with('$2')
    expect(user.password_salt).to eq(salt)
  end

  it 'still signs in with a wrapped hash' do
    user.wrap_legacy_password_hash!
    sign_in_with(self, user.login, password)

    expect(response.location).not_to include(new_user_session_path)
    expect(user.reload.encrypted_password).to start_with('$2')
  end

  it 'rejects a wrong password and keeps the legacy hash' do
    legacy_hash = user.encrypted_password
    sign_in_with(self, user.login, 'wrong password')

    # Devise re-renders the sign-in form
    expect(response).to have_http_status(:ok)
    expect(signed_in?(self)).to be(false)
    expect(user.reload.encrypted_password).to eq(legacy_hash)
  end

  it 'keeps a session that started before the upgrade' do
    first = open_session
    sign_in_with(first, user.login, password)
    expect(user.reload.encrypted_password).to start_with('$2')
    expect(signed_in?(first)).to be(true)

    # Put the legacy hash back (same salt) and upgrade it from a second session
    user.update_columns(encrypted_password: User.legacy_sha1_digest(password, salt))
    second = open_session
    sign_in_with(second, user.login, password)
    expect(user.reload.encrypted_password).to start_with('$2')

    expect(signed_in?(first)).to be(true)
    expect(signed_in?(second)).to be(true)
  end

  it "signs in with the fixtures' legacy hash format" do
    # A fresh user with user_1's stored hash and salt (password 'password'), rather than the shared fixture row,
    # which other specs may change.
    fixture = YAML.load_file(Rails.root.join('spec/fixtures/users.yml')).fetch('user_1')
    fixture_hash_user = create(:unique_user)
    fixture_hash_user.update_columns(encrypted_password: fixture['encrypted_password'],
                                     password_salt: fixture['password_salt'])
    expect(fixture_hash_user.reload.legacy_sha1_hash?).to be(true)

    sign_in_with(self, fixture_hash_user.login, 'password')

    expect(response.location).not_to include(new_user_session_path)
    expect(fixture_hash_user.reload.encrypted_password).to start_with('$2')
  end
end
