require 'spec_helper'
require 'rake'

# SEC-06: wraps legacy SHA-1 password hashes in bcrypt without needing the passwords.
describe 'fromthepage:passwords:wrap_legacy' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  before do
    Rake::Task['fromthepage:passwords:wrap_legacy'].reenable
  end

  # The task wraps every legacy hash in the (shared, never reset) test DB, fixture users included.
  # Put them back so other specs still sign those users in through the legacy path.
  around do |example|
    legacy_hashes = User.where('encrypted_password REGEXP ?', '^[0-9a-fA-F]{40}$').pluck(:id, :encrypted_password)
    example.run
  ensure
    legacy_hashes&.each { |id, hash| User.where(id: id).update_all(encrypted_password: hash) }
  end

  let(:password) { 'legacy password' }
  let(:salt) { Devise.friendly_token[0, 20] }
  let(:legacy_digest) { User.legacy_sha1_digest(password, salt) }

  let!(:legacy_user) do
    create(:unique_user).tap { |u| u.update_columns(encrypted_password: legacy_digest, password_salt: salt) }
  end
  let!(:bcrypt_user) { create(:unique_user) }
  let!(:blank_user) { create(:unique_user).tap { |u| u.update_columns(encrypted_password: '') } }

  def run_task
    expect { Rake::Task['fromthepage:passwords:wrap_legacy'].invoke }.to output(/Done:/).to_stdout
  end

  it 'wraps legacy hashes, which still validate' do
    run_task

    legacy_user.reload
    expect(legacy_user.encrypted_password).to start_with(LegacyPasswordHash::WRAPPED_PREFIX)
    expect(legacy_user.encrypted_password).not_to include(legacy_digest)
    expect(legacy_user.password_salt).to eq(salt)
    expect(legacy_user.valid_password?(password)).to be(true)
  end

  it 'leaves bcrypt and blank hashes alone' do
    bcrypt_hash = bcrypt_user.reload.encrypted_password

    run_task

    expect(bcrypt_user.reload.encrypted_password).to eq(bcrypt_hash)
    expect(blank_user.reload.encrypted_password).to eq('')
  end

  it 'can be re-run' do
    run_task
    wrapped = legacy_user.reload.encrypted_password

    Rake::Task['fromthepage:passwords:wrap_legacy'].reenable
    run_task

    expect(legacy_user.reload.encrypted_password).to eq(wrapped)
  end
end
