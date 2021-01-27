class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :masqueradable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :encryptable, :encryptor => :restful_authentication_sha1,
         :omniauth_providers => [:google_oauth2,:saml]

  include OwnerStatistic
  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]

  # allows me to get at the user from other models
  cattr_accessor :current_user

  attr_accessor :login_id

  has_many(:owner_works,
           :foreign_key => "owner_user_id",
           :class_name => 'Work')
  has_many :collections, :foreign_key => "owner_user_id"
  has_many :document_sets, :foreign_key => "owner_user_id"
  has_many :ia_works
  has_many :visits
  has_many :bulk_exports
  has_many :flags, :foreign_key => "author_user_id"
  has_one :notification, :dependent => :destroy

  has_and_belongs_to_many(:scribe_works,
                          :join_table => 'transcribe_authorizations',
                          :class_name => 'Work')
  has_and_belongs_to_many(:owned_collections,
                          :join_table => 'collection_owners',
                          :class_name => 'Collection')
  has_and_belongs_to_many(:document_set_collaborations,
                          :join_table => 'document_set_collaborators',
                          :class_name => 'DocumentSet')
  has_and_belongs_to_many(:collection_collaborations,
                          :join_table => 'collection_collaborators',
                          :class_name => 'Collection')


  has_many :page_versions, -> { order 'created_on DESC' }
  has_many :article_versions, -> { order 'created_on DESC' }
  has_many :notes, -> { order 'created_at DESC' }
  has_many :deeds

  has_many :random_collections,   -> { unrestricted.has_intro_block.not_near_complete.not_empty.random_sample },
    class_name: "Collection",  :foreign_key => "owner_user_id"
  has_many :random_document_sets, -> { unrestricted.has_intro_block.not_near_complete.not_empty.random_sample },
    class_name: "DocumentSet", :foreign_key => "owner_user_id"

  scope :owners,           -> { where(owner: true) }
  scope :trial_owners,     -> { owners.where(account_type: 'Trial') }
  scope :findaproject_owners, -> { owners.where.not(account_type: [nil, 'Trial', 'Staff']) }
  scope :paid_owners,      -> { non_trial_owners.where('paid_date > ?', Time.now) }
  scope :expired_owners,   -> { non_trial_owners.where('paid_date <= ?', Time.now) }

  validates :login, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-zA-Z0-9_\.]*\z/, message: "Invalid characters in username"}, exclusion: { in: %w(transcribe translate work collection deed), message: "Username is invalid"}
  validates :website, allow_blank: true, format: { with: URI.regexp }

  before_validation :update_display_name

  after_save :create_notifications
  #before_destroy :clean_up_orphans

  def update_display_name
    if self.owner
      self.display_name = self.real_name
    else
      self.display_name = login
    end
  end

  def self.from_omniauth(access_token)
    issuer = nil

    if access_token['extra']
      if access_token['extra']['response_object']
        if !access_token['extra']['response_object'].issuers.empty?
          issuer = access_token['extra']['response_object'].issuers.first
        end
      end
    end

    data = access_token.info

    if data['external_id']
      user = User.where(external_id: data['external_id'], sso_issuer: issuer).first
    end
    if !user && data['email']
      user = User.where(email: data['email']).first
    end
    if !user && data['email2']
      user = User.where(email: data['email2']).first
    end
    if !user && data['email3']
      user = User.where(email: data['email3']).first
    end

    # update the user's SSO if they don't have one
    if user && user.sso_issuer.nil?
      user.sso_issuer = issuer
      user.save!
    end

    # create users if they don't exist
    unless user
      email = data['email'] || data['email2'] || data['email3']
      login = email.gsub(/@.*/,'')
      # avoid duplicate logins
      while User.where(login: login).exists? do
        login += '_'
      end

      user = User.create(
         login: login,
         email: email,
         external_id: data['external_id'],
         password: Devise.friendly_token[0,20],
         display_name: data['name'],
         real_name: data['name'],
         sso_issuer: issuer
      )
    end

    user
  end

  def all_owner_collections
    Collection.where(owner_user_id: self.id).or(Collection.where(id: self.owned_collections.ids)).distinct.order(:title)
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
    if obj.is_a? DocumentSet
      obj.collection.collaborators.include?(self) || obj.collaborators.include?(self)
    else
      obj.collaborators.include?(self)
    end
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

  def name_with_identifier
    self.display_name + ' - ' + self.email
  end

  def collections
    self.owned_collections + Collection.where(:owner_user_id => self.id)#.all
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
    self.all_owner_collections.unrestricted
  end

  def unrestricted_document_sets
    DocumentSet.where(owner_user_id: self.id).where(is_public: true)
  end


  def collections_and_document_sets
    (collections + document_sets).sort_by {|obj| obj.title}
  end

  def visible_collections_and_document_sets(user)
    collections_and_document_sets.select {|cds| cds.show_to?(user) }
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

  def expunge
    self.notes.each { |note| note.destroy }
    self.page_versions.each { |version| version.expunge }
    self.article_versions.each { |version| version.expunge }
    self.deeds.each { |deed| deed.destroy }
    self.destroy!  #need to decide whether to truly delete users or not
    self.flags.each { |flag| flag.revert_content! }
  end

  def soft_delete
    if self.deeds.blank?
      self.destroy
    else
      self.login = "deleted_#{self.id}_#{self.login}"
      self.email = "deleted_#{self.email}"
      self.display_name = "[deleted]"
      self.deleted = true
      self.admin = false
      self.owner = false
      self.password = [*'A'..'Z'].sample(8).join
      self.save!
    end
  end

  def self.search(search)
    wildcard = "%#{search}%"
    where("display_name LIKE ? OR login LIKE ? OR real_name LIKE ? OR email LIKE ?", wildcard, wildcard, wildcard, wildcard)
  end

  def create_notifications
    unless self.notification
      self.notification = Notification.new
      self.notification.add_as_owner = self.activity_email
      self.notification.add_as_collaborator = self.activity_email
      self.notification.note_added = self.activity_email
      self.notification.user_activity = self.activity_email
      if self.owner
        self.notification.owner_stats = self.activity_email
      end
      self.notification.save
    end
  end
  def join_collection(collection_id)
      deed = Deed.new
      deed.collection = Collection.find(collection_id)
      deed.deed_type = DeedType::COLLECTION_JOINED
      deed.user = self
      deed.save!
  end

  def downgrade
    self.owner = false
    self.account_type = nil

    self.collections.each do |c|
      c.is_active = false
      c.restricted = true
      c.save
    end

    self.save
  end


  # Generate a unique API key
  def self.generate_api_key
    loop do
      token = SecureRandom.base64.tr('+/=', 'Qrt')
      break token unless User.exists?(api_key: token)
    end
  end

end
