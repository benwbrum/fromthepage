require 'spec_helper'

# SEC-06: passwords are bcrypt; legacy SHA-1 hashes (plain or wrapped) still validate and are upgraded.
describe User do
  let(:password) { 'correct horse' }
  let(:salt) { 'F-UbHG9zbD_sFTFk8sPR' }
  let(:legacy_digest) { Digest::SHA1.hexdigest("--#{salt}--#{password}--") }
  let(:user) { create(:unique_user) }

  def bcrypt?(hash)
    hash.start_with?('$2')
  end

  def give_legacy_hash(user, hash = legacy_digest)
    user.update_columns(encrypted_password: hash, password_salt: salt)
    user.reload
  end

  describe 'a new password' do
    it 'is stored as bcrypt and validates' do
      user.update!(password: password, password_confirmation: password)
      user.reload

      expect(bcrypt?(user.encrypted_password)).to be(true)
      expect(user.valid_password?(password)).to be(true)
      expect(user.valid_password?('wrong password')).to be(false)
    end

    it 'regenerates password_salt, which ends other sessions' do
      old_salt = user.password_salt
      user.update!(password: password, password_confirmation: password)

      expect(user.reload.password_salt).not_to eq(old_salt)
      expect(user.authenticatable_salt).to eq(user.password_salt)
    end
  end

  describe 'a legacy SHA-1 hash' do
    before { give_legacy_hash(user) }

    it 'uses the restful_authentication formula' do
      # Same value devise-encryptable's RestfulAuthenticationSha1 produced with stretches 1 and no pepper
      expect(User.legacy_sha1_digest(password, salt)).to eq(legacy_digest)
      expect(user.legacy_sha1_hash?).to be(true)
    end

    it 'validates and is upgraded to bcrypt without changing the session salt' do
      expect(user.valid_password?(password)).to be(true)

      user.reload
      expect(bcrypt?(user.encrypted_password)).to be(true)
      expect(user.password_salt).to eq(salt)
      expect(user.authenticatable_salt).to eq(salt)
      expect(user.valid_password?(password)).to be(true)
    end

    it 'is left alone after a wrong password' do
      expect(user.valid_password?('wrong password')).to be(false)

      expect(user.reload.encrypted_password).to eq(legacy_digest)
    end

    it 'leaves a password changed meanwhile alone' do
      stale = User.find(user.id)
      user.update!(password: 'a brand new one', password_confirmation: 'a brand new one')

      # stale still holds the legacy hash, but the upgrade only replaces the hash it loaded
      stale.valid_password?(password)

      expect(user.reload.valid_password?('a brand new one')).to be(true)
    end
  end

  describe 'a wrapped legacy hash' do
    before do
      give_legacy_hash(user)
      user.wrap_legacy_password_hash!
      user.reload
    end

    it 'is bcrypt over the SHA-1 digest' do
      expect(user.encrypted_password).to start_with(LegacyPasswordHash::WRAPPED_PREFIX)
      expect(user.encrypted_password).not_to include(legacy_digest)
    end

    it 'validates and is upgraded to plain bcrypt' do
      expect(user.valid_password?(password)).to be(true)

      user.reload
      expect(bcrypt?(user.encrypted_password)).to be(true)
      expect(user.password_salt).to eq(salt)
      expect(user.valid_password?(password)).to be(true)
    end

    it 'is left alone after a wrong password' do
      wrapped = user.encrypted_password

      expect(user.valid_password?('wrong password')).to be(false)
      expect(user.reload.encrypted_password).to eq(wrapped)
    end
  end

  describe 'wrap_legacy_password_hash!' do
    it 'only wraps legacy SHA-1 hashes' do
      user.update!(password: password, password_confirmation: password)
      bcrypt_hash = user.reload.encrypted_password

      expect(user.wrap_legacy_password_hash!).to be(false)
      expect(user.reload.encrypted_password).to eq(bcrypt_hash)
    end
  end

  describe 'unusable hashes' do
    it 'rejects a blank hash' do
      user.update_columns(encrypted_password: '')

      expect(user.reload.valid_password?('')).to be(false)
      expect(user.valid_password?(password)).to be(false)
    end

    it 'rejects a malformed hash without raising' do
      user.update_columns(encrypted_password: 'not-a-hash')
      expect(user.reload.valid_password?(password)).to be(false)

      user.update_columns(encrypted_password: "#{LegacyPasswordHash::WRAPPED_PREFIX}garbage")
      expect(user.reload.valid_password?(password)).to be(false)
    end
  end

  describe 'password length' do
    def errors_for(new_password)
      user.password = new_password
      user.password_confirmation = new_password
      user.valid?
      user.errors[:password]
    end

    it 'requires at least 8 characters' do
      expect(errors_for('a' * 7)).not_to be_empty
      expect(errors_for('a' * 8)).to be_empty
    end

    it 'allows up to 72 bytes' do
      expect(errors_for('a' * 72)).to be_empty
      expect(errors_for('a' * 73)).not_to be_empty
    end

    it 'counts bytes, not characters' do
      # 25 three-byte characters: 25 characters, 75 bytes
      expect(errors_for('€' * 25)).not_to be_empty
      expect(errors_for('€' * 24)).to be_empty
    end
  end

  describe '#soft_delete' do
    it 'sets an unguessable password' do
      collection = create(:collection, owner_user_id: create(:unique_user, :owner).id, works: [])
      work = create(:work, collection: collection, owner_user_id: collection.owner_user_id)
      create(:deed, user: user, collection: collection, work: work)
      # Loaded fresh, as in production (the factory instance still holds a password_confirmation)
      User.find(user.id).soft_delete

      user.reload
      expect(user.deleted).to be(true)
      expect(bcrypt?(user.encrypted_password)).to be(true)
      expect(user.valid_password?('password')).to be(false)
    end
  end
end
