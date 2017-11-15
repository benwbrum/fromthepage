class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :masqueradable, 
         :recoverable, :rememberable, :trackable, :validatable,
         :encryptable, :encryptor => :restful_authentication_sha1

  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :email, :password, :password_confirmation, :remember_me, :owner, :display_name, :location, :website, :about, :print_name, :account_type, :paid_date, :slug

  # allows me to get at the user from other models
  cattr_accessor :current_user

  attr_accessor :login_id

  has_many(:owner_works,
           { :foreign_key => "owner_user_id",
             :class_name => 'Work' })
  has_many :collections, :foreign_key => "owner_user_id"
  has_many :oai_sets
  has_many :ia_works
  has_many :omeka_sites
  has_many :visits
  has_and_belongs_to_many(:scribe_works,
                          { :join_table => 'transcribe_authorizations',
                            :class_name => 'Work'})
  has_and_belongs_to_many(:owned_collections,
                          { :join_table => 'collection_owners',
                            :class_name => 'Collection'})
  has_and_belongs_to_many(:document_set_collaborations,
                          { :join_table => 'document_set_collaborators',
                            :class_name => 'DocumentSet'
                            })
  has_and_belongs_to_many(:collection_collaborations,
                          { :join_table => 'collection_collaborators',
                            :class_name => 'Collection'})


  has_many :page_versions, -> { order 'created_on DESC' }
  has_many :article_versions, -> { order 'created_on DESC' }
  has_many :notes, -> { order 'created_at DESC' }
  has_many :deeds

  validates :display_name, presence: true
  validates :login, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-zA-Z0-9_\.]*\z/, message: "Invalid characters in username"}, exclusion: { in: %w(transcribe translate work collection deed), message: "Username is invalid"}
  validates :website, allow_blank: true, format: { with: URI.regexp }
  
  after_destroy :clean_up_orphans

  def all_owner_collections
    query = Collection.where("owner_user_id = ? or collections.id in (?)", self.id, self.owned_collections.ids)
    Collection.where(query.where_values.inject(:or)).uniq.order(:title)
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
    works = Work.where(collection_id: self.all_owner_collections.ids)
    return works
  end

  def can_transcribe?(work)
    !work.restrict_scribes || self.like_owner?(work) || work.scribes.include?(self)
  end

  def collaborator?(obj)
    obj.collaborators.include?(self)
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
    if DocumentSet == obj.class
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
  
  def unrestricted_collections
    collections = self.all_owner_collections.unrestricted
  end

  def unrestricted_document_sets
    DocumentSet.where(owner_user_id: self.id).where(is_public: true)
  end

  def document_sets
    DocumentSet.where(owner_user_id: self.id)
  end

  def owned_collection_and_document_sets
    (unrestricted_collections + unrestricted_document_sets).sort_by {|obj| obj.title}
  end

  def slug_candidates
    if self.slug
      [:slug]
    else
      [
        :login,
        [:login, :id]
      ]
    end
  end

  def should_generate_new_friendly_id?
    slug_changed? || super
  end

  def normalize_friendly_id(string)
    super.truncate(240, separator: '-', omission: '').gsub('_', '-')
  end

  def clean_up_orphans
    self.notes.destroy_all
    self.article_versions.destroy_all
    self.page_versions.destroy_all
    self.deeds.destroy_all
  end
  def self.search(search)
    where("display_name LIKE ?", "%#{search}%")
    where("login LIKE ?", "%#{search}%")
  end

end