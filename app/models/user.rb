require 'digest/sha1'
class User < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password
  # allows me to get at the user from other models
  cattr_accessor :current_user
  
  validates_presence_of     :login
  validates_presence_of     :password,                    :if => :password_required?
  validates_presence_of     :password_confirmation,       :if => :password_required?
  validates_length_of       :password, :within => 4..40,  :if => :password_required?
  validates_confirmation_of :password,                    :if => :password_required?
  validates_length_of       :login,    :within => 3..40
#  validates_length_of       :email,    :within => 3..100, :if => :email_required?
  validates_uniqueness_of   :login, :case_sensitive => false
  before_save :encrypt_password

  has_many(:owner_works, 
           { :foreign_key => "owner_user_id",
             :class_name => 'Work' })
  has_many :image_sets, :foreign_key => "owner_user_id"
  has_many :oai_sets
  has_many :ia_works
  has_and_belongs_to_many(:scribe_works, 
                          { :join_table => 'transcribe_authorizations', 
                            :class_name => 'Work'})
  has_and_belongs_to_many(:owned_collections, 
                          { :join_table => 'collection_owners', 
                            :class_name => 'Collection'})
  has_many :page_versions, :order => 'created_on DESC'
  has_many :article_versions, :order => 'created_on DESC'
  has_many :notes, :order => 'created_at DESC'
  has_many :deeds

  def can_transcribe?(work)
    !work.restrict_scribes || self == work.owner || work.scribes.include?(self)
  end
  
  def like_owner?(obj)
    if Collection == obj.class
      return self == obj.owner || obj.owners.include?(self)      
    end
    return false
  end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    # save(false)
    save(:validate => false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
end
