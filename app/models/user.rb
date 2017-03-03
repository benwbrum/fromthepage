class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :masqueradable, 
         :recoverable, :rememberable, :trackable, :validatable,
         :encryptable, :encryptor => :restful_authentication_sha1

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :email, :password, :password_confirmation, :remember_me, :owner, :display_name, :location, :website, :about, :print_name, :account_type, :paid_date

  # allows me to get at the user from other models
  cattr_accessor :current_user

  attr_accessor :login_id

  has_many(:owner_works,
           { :foreign_key => "owner_user_id",
             :class_name => 'Work' })
  has_many :collections, :foreign_key => "owner_user_id"
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
  has_many :page_versions, -> { order 'created_on DESC' }
  has_many :article_versions, -> { order 'created_on DESC' }
  has_many :notes, -> { order 'created_at DESC' }
  has_many :deeds

  validates :display_name, presence: true
  validates :login, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-zA-Z0-9_\.]*\z/, message: "Invalid characters"}
  validates :website, allow_blank: true, format: { with: URI.regexp }

  def all_owner_collections
    (self.owned_collections + self.collections).uniq.sort {|a, b| a.title <=> b.title }
  end

  def most_recently_managed_collection_id
    last_work = self.owner_works.order(:created_on).last
    if last_work && last_work.collection
      last_work.collection.id.to_i
    else
      nil
    end
  end

  def owner_works
    collections = self.all_owner_collections
    works = []
    collections.each do |c|
      c.works.each do |w|
        works << w
      end
    end
    return works
  end

  def can_transcribe?(work)
    !work.restrict_scribes || self.like_owner?(work) || work.scribes.include?(self)
  end

  def like_owner?(obj)
    if Collection == obj.class
      return self == obj.owner || obj.owners.include?(self)
    end
    if Work == obj.class
      if obj.collection
        return self == obj.collection.owner || obj.collection.owners.include?(self)
      else
        self == obj.owner      
      end
    end
    return false
  end

  def display_name
    if self.guest
      "Guest"
    else
      self[:display_name] || self[:login]
    end
  end

  def collections
    self.owned_collections + Collection.where(:owner_user_id => self.id)#.all
  end

  def owned_page_count
    count = 0
    self.all_owner_collections.each do |c|
      count = count + c.page_count
    end
    return count
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login_id)
      where(conditions).where(["login = :value OR lower(email) = lower(:value)", { :value => login}]).first
    else
      where(conditions).first
    end
  end


end