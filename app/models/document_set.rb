# == Schema Information
#
# Table name: document_sets
#
#  id                         :integer          not null, primary key
#  default_orientation        :string(255)
#  description                :text(65535)
#  featured_at                :datetime
#  pct_completed              :integer
#  picture                    :string(255)
#  slug                       :string(255)
#  title                      :string(255)
#  visibility                 :integer          default("private"), not null
#  works_count                :integer          default(0)
#  created_at                 :datetime
#  updated_at                 :datetime
#  collection_id              :integer
#  next_untranscribed_page_id :integer
#  owner_user_id              :integer
#
# Indexes
#
#  index_document_sets_on_collection_id  (collection_id)
#  index_document_sets_on_owner_user_id  (owner_user_id)
#  index_document_sets_on_slug           (slug) UNIQUE
#
class DocumentSet < ApplicationRecord
  include DocumentSetStatistic

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :history]

  before_create :fill_featured_at
  before_save :uniquify_slug
  # validate :slug_uniqueness_across_objects

  mount_uploader :picture, PictureUploader

  belongs_to :owner, class_name: 'User', foreign_key: 'owner_user_id', optional: true
  belongs_to :collection, optional: true
  belongs_to :next_untranscribed_page, foreign_key: 'next_untranscribed_page_id', class_name: 'Page', optional: true

  has_many :document_set_works
  has_many :works, -> { order(:title) }, through: :document_set_works
  has_many :pages, through: :works
  has_many :articles, -> { distinct }, through: :works
  has_many :notes, -> { order(created_at: :desc) }, through: :works
  has_many :deeds, -> (document_set) {
    where(work_id: document_set.works.select(:id))
      .includes(:work)
      .reorder('deeds.created_at DESC')
  }, through: :collection, source: :deeds

  has_and_belongs_to_many :collaborators, class_name: 'User', join_table: :document_set_collaborators

  has_many :bulk_exports, dependent: :delete_all

  after_save :set_next_untranscribed_page

  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :slug, format: { with: /[[:alpha:]]/ }

  scope :unrestricted, -> { where(visibility: [:public, :read_only]) }
  scope :restricted, -> { where(visibility: [:private]) }

  scope :carousel, -> {
    where(pct_completed: [nil, 1..90])
      .joins(:collection)
      .where.not(collections: { picture: nil })
      .where.not(description: [nil, ''])
      .unrestricted
      .reorder(Arel.sql('RAND()'))
  }
  scope :has_intro_block, -> { where.not(description: [nil, '']) }
  scope :has_picture, -> { where.not(picture: nil) }
  scope :not_near_complete, -> { where(pct_completed: [nil, 0..90]) }
  scope :not_empty, -> { where.not(works_count: [0, nil]) }

  scope :featured_projects, -> {
    joins(works: :pages)
      .joins(:owner)
      .where(owner: { deleted: false })
      .unrestricted.where("LOWER(document_sets.title) NOT LIKE 'test%'")
      .where.not(featured_at: nil)
      .distinct
  }

  enum :visibility, {
    private: 0,
    public: 1,
    read_only: 2
  }, prefix: :visibility

  update_index('document_sets', if: -> { ELASTIC_ENABLED && !destroyed? }) { self }
  after_destroy :handle_index_deletion

  def self.es_search(query:, user: nil, is_public: true)
    blocked_collections = []
    collection_collabs = []
    docset_collabs = []

    if user.present?
      blocked_collections = user.blocked_collections.pluck(:id)
      collection_collabs  = user.collection_collaborations.pluck(:id)
      collection_collabs += user.owned_collections.pluck(:id)
      docset_collabs      = user.document_set_collaborations.pluck(:id).map { |x| "docset-#{x}" }
    end

    DocumentSetsIndex.query(
      bool: {
        must: {
          simple_query_string: {
            query: query,
            fields: [
              'title^2',
              'title.no_underscores^1.3',
              'intro_block',
              'slug'
            ]
          }
        },
        filter: [
          { term: { is_docset: true } },
          {
            bool: {
              must_not: [
                { terms: { collection_id: blocked_collections } }
              ],
              should: [
                { term: { is_public: is_public } },
                { term: { owner_user_id: user&.id || -1 } },
                { terms: { collection_id: collection_collabs } },
                { terms: { _id: docset_collabs } }
              ],
              minimum_should_match: 1
            }
          }
        ]
      }
    )
  end

  def show_to?(user)
    is_public? || user&.like_owner?(self) || user&.collaborator?(self)
  end

  def intro_block
    description
  end

  def messageboards_enabled
    false
  end

  def messageboards_enabled?
    messageboards_enabled
  end

  def uniquify_slug
    self.slug = "#{slug}-set" if Collection.where(slug: slug).exists?
  end

  delegate :metadata_coverages,          to: :collection
  delegate :enable_spellcheck,           to: :collection
  delegate :reviewers,                   to: :collection
  delegate :facet_configs,               to: :collection
  delegate :text_entry?,                 to: :collection
  delegate :metadata_entry?,             to: :collection
  delegate :metadata_only_entry?,        to: :collection
  delegate :text_and_metadata_entry?,    to: :collection
  delegate :hide_completed,              to: :collection
  delegate :review_workflow,             to: :collection
  delegate :review_type,                 to: :collection
  delegate :user_download,               to: :collection
  delegate :subjects_disabled,           to: :collection
  delegate :editor_buttons,              to: :collection
  delegate :categories,                  to: :collection
  delegate :active?,                     to: :collection
  delegate :footer_block,                to: :collection
  delegate :help,                        to: :collection
  delegate :link_help,                   to: :collection
  delegate :voice_recognition,           to: :collection
  delegate :language,                    to: :collection
  delegate :text_language,               to: :collection
  delegate :field_based,                 to: :collection
  delegate :transcription_fields,        to: :collection
  delegate :metadata_fields,             to: :collection
  delegate :description_instructions,    to: :collection
  delegate :facets_enabled?,             to: :collection
  delegate :api_access,                  to: :collection
  delegate :alphabetize_works,           to: :collection
  delegate :institution_signature,       to: :collection
  delegate :most_recent_deed_created_at, to: :collection

  def export_subject_index_as_csv
    subject_link = SubjectExporter::Exporter.new(self)

    subject_link.export
  end

  def export_subject_details_as_csv
    subjects = SubjectDetailsExporter::Exporter.new(self)

    subjects.export
  end

  def export_subject_distribution_as_csv(subject)
    subjects = SubjectDistributionExporter::Exporter.new(self, subject)

    subjects.export
  end

  def supports_document_sets
    false
  end

  def restricted
    visibility_private?
  end

  def picture_url(thumb = nil)
    if picture.blank?
      collection.picture.url(thumb)
    else
      picture.url(thumb)
    end
  end

  def set_next_untranscribed_page
    first_work = works.unrestricted.where.not(next_untranscribed_page_id: nil).order_by_incomplete.first
    first_page = first_work&.next_untranscribed_page
    page_id = first_page&.id

    update_columns(next_untranscribed_page_id: page_id)
  end

  def find_next_untranscribed_page_for_user(user)
    return nil unless has_untranscribed_pages?
    return next_untranscribed_page if user.can_transcribe?(next_untranscribed_page.work, self)

    public = works.unrestricted
                  .where.not(next_untranscribed_page_id: nil)
                  .order_by_incomplete

    public&.first&.next_untranscribed_page
  end

  def has_untranscribed_pages?
    next_untranscribed_page.present?
  end

  def fill_featured_at
    return if self.visibility.nil? || self.visibility.to_sym == :private

    self.featured_at = Time.current
  end

  def slug_candidates
    if self.slug
      [:slug]
    else
      [
        :title,
        [:title, :id]
      ]
    end
  end

  def should_generate_new_friendly_id?
    slug_changed? || super
  end

  def normalize_friendly_id(string)
    super.truncate(240, separator: '-', omission: '').gsub('_', '-')
  end

  def search_works(search)
    works.where('title LIKE ? OR searchable_metadata like ?', "%#{search}%", "%#{search}%")
  end

  def self.search(search)
    sql = "title like ? OR slug LIKE ? OR owner_user_id in (select id from \
           users where owner=1 and display_name like ?)"
    where(sql, "%#{search}%", "%#{search}%", "%#{search}%")
  end

  def default_orientation
    if !self[:default_orientation].nil?
      self[:default_orientation]
    elsif self[:field_based]
      'ttb'
    else
      'ltr'
    end
  end

  def sc_collection
    # association does not exist for document sets
    nil
  end

  def user_help
    collection.owner.help
  end

  def is_public
    visibility_public?
  end

  def is_public?
    visibility_public?
  end

  public :user_help

  private

  def handle_index_deletion
    return unless ELASTIC_ENABLED

    Chewy.client.delete(
      index: DocumentSetsIndex.index_name,
      id: "docset-#{id}"
    )
  rescue StandardError => _e
    # Make sure it does not fail
  end
end
