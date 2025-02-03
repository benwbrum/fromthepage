# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  about                     :text(65535)
#  account_type              :string(255)
#  activity_email            :boolean
#  admin                     :boolean          default(FALSE)
#  api_key                   :string(255)
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string(255)
#  deleted                   :boolean          default(FALSE)
#  dictation_language        :string(255)      default("en-US")
#  display_name              :string(255)
#  email                     :string(255)
#  encrypted_password        :string(255)      default(""), not null
#  footer_block              :text(16777215)
#  guest                     :boolean
#  help                      :text(65535)
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string(255)
#  location                  :string(255)
#  login                     :string(255)
#  orcid                     :string(255)
#  owner                     :boolean          default(FALSE)
#  paid_date                 :datetime
#  password_salt             :string(255)      default(""), not null
#  picture                   :string(255)
#  preferred_locale          :string(255)
#  provider                  :string(255)
#  real_name                 :string(255)
#  remember_created_at       :datetime
#  remember_token            :string(255)
#  remember_token_expires_at :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  sign_in_count             :integer          default(0), not null
#  slug                      :string(255)
#  sso_issuer                :string(255)
#  start_date                :datetime
#  uid                       :string(255)
#  website                   :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  external_id               :string(255)
#
# Indexes
#
#  index_users_on_deleted               (deleted)
#  index_users_on_login                 (login)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_slug                  (slug) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :masqueradable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :encryptable, :encryptor => :restful_authentication_sha1,
         :omniauth_providers => [:google_oauth2,:saml]

  include OwnerStatistic
  include ElasticDelta
  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]

  # allows me to get at the user from other models
  cattr_accessor :current_user

  attr_accessor :login_id

  mount_uploader :picture, PictureUploader

  has_many(:owner_works,
           :foreign_key => "owner_user_id",
           :class_name => 'Work')
  has_many :collections, :foreign_key => "owner_user_id"
  has_many :document_sets, :foreign_key => "owner_user_id"
  has_many :ia_works
  has_many :visits
  has_many :bulk_exports
  has_many :document_uploads
  has_many :external_api_requests
  has_many :flags, :foreign_key => "author_user_id"
  has_one :notification, :dependent => :destroy

  has_many :collection_blocks, dependent: :destroy
  has_many :blocked_collections, through: :collection_blocks, source: :collection
  has_many :ahoy_activity_summaries

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
  has_and_belongs_to_many(:review_collections,
                          :join_table => 'collection_reviewers',
                          :class_name => 'Collection')


  has_many :page_versions, -> { order 'created_on DESC' }
  has_many :article_versions, -> { order 'created_on DESC' }
  has_many :notes, -> { order 'created_at DESC' }
  has_many :deeds

  has_many :random_collections,   -> { unrestricted.has_intro_block.not_near_complete.not_empty.random_sample },
    class_name: "Collection",  :foreign_key => "owner_user_id"
  has_many :random_document_sets, -> { unrestricted.has_intro_block.not_near_complete.not_empty.random_sample },
    class_name: "DocumentSet", :foreign_key => "owner_user_id"

  has_many :metadata_description_versions, :dependent => :destroy

  scope :owners,           -> { where(owner: true) }
  scope :trial_owners,     -> { owners.where(account_type: 'Trial') }
  scope :findaproject_owners, -> { owners.where.not(account_type: [nil, 'Trial', 'Staff']) }
  scope :paid_owners,      -> { non_trial_owners.where('paid_date > ?', Time.now) }
  scope :expired_owners,   -> { non_trial_owners.where('paid_date <= ?', Time.now) }
  scope :active_mailers,   -> { where(activity_email: true)}

  validates :login, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: /\A[^<>]*\z/,
                              message: ->(_, _) { I18n.t('devise.errors.messages.login.format') } },
                    exclusion: { in: %w[transcribe translate work collection deed],
                                 message: ->(_, _) { I18n.t('devise.errors.messages.login.exclusion') } }

  validates :website, allow_blank: true, format: { with: URI.regexp }
  validate :email_does_not_match_denylist

  before_validation :update_display_name

  after_save :create_notifications
  after_create :set_default_footer_block
  #before_destroy :clean_up_orphans

  def as_indexed_json
    return {
      _id: self.id,
      about: self.about,
      display_name: self.display_name,
      login: self.login,
      real_name: self.real_name,
      website: self.website
    }
  end

  def self.es_match_query(query)
    return {
      bool: {
        must: {
          simple_query_string: {
            query: query,
            fields: [
              "about",
              "real_name",
              "website"
            ]
          }
        },
        filter: [
          # Need index filter for cross collection search
          {prefix: {_index: "ftp_user"}}
        ]
      }
    }
  end

  def email_does_not_match_denylist
    raw = PageBlock.where(view: "email_denylist").first
    if raw
      patterns = raw.html.split(/\s+/)
      if patterns.detect {|pattern| self.email.match(/#{pattern}/) }
        errors.add(:email, 'error 38')
      end
    end
  end


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

    if data['external_id'] && !data['external_id'].blank?
      user = User.where(external_id: data['external_id'], sso_issuer: issuer).first
    end
    if !user && !data['email'].blank?
      user = User.where(email: data['email']).first
    end
    if !user && !data['email2'].blank?
      user = User.where(email: data['email2']).first
    end
    if !user && !data['email3'].blank?
      user = User.where(email: data['email3']).first
    end

    logger.info("User record before save:")
    logger.info(user.to_json)
    logger.info("Data from SAML response:")
    logger.info(data.to_json)

    # update the user's SSO if they don't have one
    if user && user.sso_issuer.nil?
      user.sso_issuer = issuer
      user.save!
    end

    # create users if they don't exist
    unless user
      email = data['email3'] unless data['email3'].blank?
      email = data['email2'] unless data['email2'].blank?
      email = data['email'] unless data['email'].blank?
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

  def can_review?(obj)
    # object could be a page or a collection
    if obj.is_a? Page
      obj=obj.work.collection
    end

    if obj.review_type == Collection::ReviewType::RESTRICTED
      obj.reviewers.include?(self) || self.like_owner?(obj)
    else
      true
    end
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
    # collection show_to? logic:
    #  (!self.restricted && self.works.present?) || (user && user.like_owner?(self)) || (user && user.collaborator?(self))
    # document set show_to? logic:
    #     (!self.restricted && self.works.present?) || (user && user.like_owner?(self)) || (user && user.collaborator?(self))
    public_collections = self.unrestricted_collections
    blocked_collection_ids = CollectionBlock.where(user_id: user&.id).pluck(:collection_id)
    filtered_public_collections = public_collections.where.not(id: blocked_collection_ids)
    public_sets = self.unrestricted_document_sets

    if user
      collaborator_collections = self.all_owner_collections.where(:restricted => true).joins(:collaborators).where("collection_collaborators.user_id = ?", user.id)
      owned_collections = self.owned_collections

      collaborator_sets = self.document_sets.where(:is_public => false).joins(:collaborators).where("document_set_collaborators.user_id = ?", user.id)
      parent_collaborator_sets = []
      collaborator_collections.each{|c| parent_collaborator_sets += c.document_sets}

      (filtered_public_collections+collaborator_collections+owned_collections+public_sets+collaborator_sets+parent_collaborator_sets).uniq
    else
      (filtered_public_collections+public_sets)
    end
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

  def set_default_footer_block
    self.footer_block = "For questions about this project, contact at."
    save
  end

  def organization?
    self.owner? && self.account_type != 'Staff'
  end

  def staff?
    self.account_type == 'Staff'
  end

end
