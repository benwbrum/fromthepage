# Passwords are hashed with Devise's bcrypt. Accounts from the restful_authentication era still have a
# legacy hash in encrypted_password, in one of two formats:
#
#   legacy SHA-1   40 hex chars: SHA1("--#{password_salt}--#{password}--") (one round, no pepper)
#   wrapped SHA-1  "sha1-bcrypt:" + bcrypt(legacy SHA-1 digest), written by
#                  `rake fromthepage:passwords:wrap_legacy` so no plain SHA-1 hash stays at rest
#
# Either one is checked here and, when the password matches, replaced with a plain bcrypt hash.
#
# Sessions and remember-me cookies are tied to authenticatable_salt, which stays password_salt (as it
# was under devise-encryptable). An upgrade doesn't touch password_salt, so nobody is logged out by it.
# Setting a new password does regenerate it, which still ends the user's other sessions.
module LegacyPasswordHash
  extend ActiveSupport::Concern

  LEGACY_SHA1_FORMAT = /\A\h{40}\z/
  WRAPPED_PREFIX = 'sha1-bcrypt:'.freeze

  # bcrypt ignores everything after the first 72 bytes of the password.
  BCRYPT_MAX_BYTES = 72

  included do
    validate :password_within_bcrypt_limit
  end

  class_methods do
    def legacy_sha1_digest(password, salt)
      Digest::SHA1.hexdigest(['', salt, password, ''].join('--'))
    end

    def wrap_legacy_digest(sha1_digest)
      "#{WRAPPED_PREFIX}#{BCrypt::Password.create(sha1_digest, cost: stretches)}"
    end
  end

  def valid_password?(password)
    valid =
      if legacy_sha1_hash?
        Devise.secure_compare(encrypted_password, self.class.legacy_sha1_digest(password, password_salt))
      elsif wrapped_legacy_hash?
        wrapped_password_matches?(password)
      else
        return bcrypt_password_matches?(password)
      end

    upgrade_password_hash(password) if valid
    valid
  end

  def password=(new_password)
    self.password_salt = Devise.friendly_token[0, 20] if new_password.present?
    super
  end

  def authenticatable_salt
    password_salt.presence || super
  end

  def legacy_sha1_hash?
    LEGACY_SHA1_FORMAT.match?(encrypted_password.to_s)
  end

  def wrapped_legacy_hash?
    encrypted_password.to_s.start_with?(WRAPPED_PREFIX)
  end

  # Replaces a plain legacy SHA-1 hash with the wrapped one. Needs no password. Returns true if it wrote.
  def wrap_legacy_password_hash!
    return false unless legacy_sha1_hash?

    replace_encrypted_password(self.class.wrap_legacy_digest(encrypted_password))
  end

  private

  def bcrypt_password_matches?(password)
    Devise::Encryptor.compare(self.class, encrypted_password, password)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def wrapped_password_matches?(password)
    bcrypt = BCrypt::Password.new(encrypted_password.delete_prefix(WRAPPED_PREFIX))
    sha1_digest = self.class.legacy_sha1_digest(password, password_salt)
    Devise.secure_compare(BCrypt::Engine.hash_secret(sha1_digest, bcrypt.salt), bcrypt.to_s)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def upgrade_password_hash(password)
    return unless persisted?

    replace_encrypted_password(Devise::Encryptor.digest(self.class, password))
  end

  # Only replaces the hash this record was loaded with, so a concurrent password change is never
  # overwritten. Skips validations, callbacks and updated_at, like update_columns.
  def replace_encrypted_password(new_hash)
    updated = self.class.where(id: id, encrypted_password: encrypted_password)
                  .update_all(encrypted_password: new_hash)
    return false if updated.zero?

    self.encrypted_password = new_hash
    clear_attribute_change(:encrypted_password)
    true
  end

  def password_within_bcrypt_limit
    return if password.blank? || password.bytesize <= BCRYPT_MAX_BYTES

    errors.add(:password, :too_long, count: BCRYPT_MAX_BYTES)
  end
end
