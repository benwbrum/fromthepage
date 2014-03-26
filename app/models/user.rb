class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
	 :encryptable, :encryptor => :restful_authentication_sha1

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
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

  has_many(:owner_works, 
           { :foreign_key => "owner_user_id",
             :class_name => 'Work' })
  has_many :image_sets, :foreign_key => "owner_user_id"
  has_many :oai_sets
  has_many :ia_works
  has_many :omeka_sites
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

  def to_i
    self.id
  end

  def can_transcribe?(work)
    !work.restrict_scribes || self == work.owner || work.scribes.include?(self)
  end
  
  def like_owner?(obj)
    if Collection == obj.class
      return self == obj.owner || obj.owners.include?(self)      
    end
    return false
  end
  
end
