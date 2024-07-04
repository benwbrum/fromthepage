# == Schema Information
#
# Table name: document_sets
#
#  id                         :integer          not null, primary key
#  default_orientation        :string(255)
#  description                :text(65535)
#  is_public                  :boolean
#  pct_completed              :integer
#  picture                    :string(255)
#  slug                       :string(255)
#  title                      :string(255)
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
  before_save :uniquify_slug
  # validate :slug_uniqueness_across_objects

  mount_uploader :picture, PictureUploader

  belongs_to :owner, class_name: 'User', foreign_key: 'owner_user_id', optional: true
  belongs_to :collection, optional: true
  belongs_to :next_untranscribed_page, class_name: 'Page', optional: true

  has_many :pages, through: :works

  has_many :document_set_works
  has_many :works, -> { order 'title' }, through: :document_set_works

  has_and_belongs_to_many :collaborators, class_name: 'User', join_table: :document_set_collaborators

  has_many :bulk_exports, dependent: :delete_all

  after_save :set_next_untranscribed_page

  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :slug, format: { with: /[[:alpha:]]/ }

  scope :unrestricted, -> { where(is_public: true) }
  scope :restricted, -> { where(is_public: false) }
  scope :carousel, -> {
                     where(pct_completed: [nil, 1..90]).joins(:collection).where.not(collections: { picture: nil }).where.not(description: [nil, '']).where(is_public: true).reorder(Arel.sql('RAND()'))
                   }
  scope :has_intro_block, -> { where.not(description: [nil, '']) }
  scope :not_near_complete, -> { where(pct_completed: [nil, 0..90]) }
  scope :not_empty, -> { where.not(works_count: [0, nil]) }

  scope :random_sample, -> (sample_size = 5) do
    carousel
    reorder(Arel.sql('RAND()')) unless sample_size > 1
    limit(sample_size).reorder(Arel.sql('RAND()'))
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
    return unless Collection.exists?(slug:)

    self.slug = "#{slug}-set"
  end

  delegate :metadata_coverages, to: :collection

  delegate :enable_spellcheck, to: :collection

  delegate :reviewers, to: :collection

  delegate :facet_configs, to: :collection

  delegate :text_entry?, to: :collection

  def metadata_entry?
    collection.text_entry?
  end

  delegate :metadata_only_entry?, to: :collection

  delegate :text_and_metadata_entry?, to: :collection

  delegate :hide_completed, to: :collection

  delegate :review_workflow, to: :collection

  delegate :review_type, to: :collection

  delegate :user_download, to: :collection

  delegate :subjects_disabled, to: :collection

  delegate :editor_buttons, to: :collection

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

  def articles
    Article.joins(:pages).where(pages: { work_id: works.ids }).distinct
  end

  delegate :categories, to: :collection

  def supports_document_sets
    false
  end

  def notes
    Note.where(work_id: works.ids).order('created_at DESC')
  end

  def deeds
    collection.deeds.where(work_id: works.ids).joins(:work).includes(:work).reorder('deeds.created_at DESC')
  end

  def restricted
    !is_public
  end

  delegate :active?, to: :collection

  delegate :footer_block, to: :collection

  delegate :help, to: :collection

  delegate :link_help, to: :collection

  delegate :voice_recognition, to: :collection

  delegate :language, to: :collection

  delegate :text_language, to: :collection

  delegate :field_based, to: :collection

  def picture_url(thumb = nil)
    if picture.blank?
      collection.picture.url(thumb)
    else
      picture.url(thumb)
    end
  end

  delegate :transcription_fields, to: :collection

  delegate :metadata_fields, to: :collection

  delegate :description_instructions, to: :collection

  delegate :text_entry?, to: :collection

  delegate :metadata_entry?, to: :collection

  def set_next_untranscribed_page
    first_work = works.order_by_incomplete.first
    first_page = first_work&.next_untranscribed_page
    page_id = first_page&.id

    update_columns(next_untranscribed_page_id: page_id)
  end

  def find_next_untranscribed_page_for_user(user)
    return nil unless has_untranscribed_pages?
    return next_untranscribed_page if user.can_transcribe?(next_untranscribed_page.work)

    public = works.
      where.not(next_untranscribed_page_id: nil).
      unrestricted.
      order_by_incomplete

    return public.first.next_untranscribed_page unless public.empty?

    private = works.
      where.not(next_untranscribed_page_id: nil).
      restricted.
      order_by_incomplete

    wk = private.find { |w| user.can_transcribe?(w) }

    wk&.next_untranscribed_page
  end

  def has_untranscribed_pages?
    next_untranscribed_page.present?
  end

  def slug_candidates
    if slug
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

  def search_collection_works(search)
    collection.search_works(search)
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

  delegate :facets_enabled?, to: :collection

  # association does not exist for document sets
  def sc_collection
    nil
  end

  delegate :api_access, to: :collection

  delegate :alphabetize_works, to: :collection

  delegate :institution_signature, to: :collection

  delegate :most_recent_deed_created_at, to: :collection

  def user_help
    collection.owner.help
  end

  public :user_help

end
