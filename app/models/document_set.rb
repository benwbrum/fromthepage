class DocumentSet < ApplicationRecord
  include DocumentSetStatistic

  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]
  before_save :uniquify_slug
  # validate :slug_uniqueness_across_objects

  mount_uploader :picture, PictureUploader

  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id', optional: true
  belongs_to :collection, optional: true
  belongs_to :next_untranscribed_page, foreign_key: 'next_untranscribed_page_id', class_name: "Page", optional: true

  has_many :pages, through: :works

  has_many :document_set_works
  has_many :works, -> { order 'title' }, through: :document_set_works

  has_and_belongs_to_many :collaborators, :class_name => 'User', :join_table => :document_set_collaborators

  has_many :bulk_exports, :dependent => :delete_all

  after_save :set_next_untranscribed_page

  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :slug, format: { with: /[[:alpha:]]/ }

  scope :unrestricted, -> { where(is_public: true)}
  scope :restricted, -> { where(is_public: false)}
  scope :carousel, -> {where(pct_completed: [nil, 1..90]).joins(:collection).where.not(collections: {picture: nil}).where.not(description: [nil, '']).where(is_public: true).reorder(Arel.sql("RAND()"))}
  scope :has_intro_block, -> { where.not(description: [nil, '']) }
  scope :not_near_complete, -> { where(pct_completed: [nil, 0..90]) }
  scope :not_empty, -> { where.not(works_count: [0, nil]) }

  scope :random_sample, -> (sample_size = 5) do
    carousel
    reorder(Arel.sql("RAND()")) unless sample_size > 1
    limit(sample_size).reorder(Arel.sql("RAND()"))
  end

  def show_to?(user)
    self.is_public? || (user && user.like_owner?(self)) || (user && user.collaborator?(self))
  end

  def intro_block
    self.description
  end

  def messageboards_enabled
    false
  end

  def messageboards_enabled?
    self.messageboards_enabled
  end

  def uniquify_slug
    if Collection.where(slug: self.slug).exists?
      self.slug = self.slug+'-set'
    end
  end

  def metadata_coverages
    self.collection.metadata_coverages
  end

  def enable_spellcheck
    self.collection.enable_spellcheck
  end

  def reviewers
    self.collection.reviewers
  end

  def facet_configs
    self.collection.facet_configs
  end

  def text_entry?
    self.collection.text_entry?
  end

  def metadata_entry?
    self.collection.text_entry?
  end

  def metadata_only_entry?
    self.collection.metadata_only_entry?
  end

  def text_and_metadata_entry?
    self.collection.text_and_metadata_entry?
  end


  def hide_completed
    self.collection.hide_completed
  end

  def review_workflow
    self.collection.review_workflow
  end

  def review_type
    self.collection.review_type
  end

  def user_download
    self.collection.user_download
  end

  def subjects_disabled
    self.collection.subjects_disabled
  end

  def editor_buttons
    self.collection.editor_buttons
  end

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
    Article.joins(:pages).where(pages: {work_id: self.works.ids}).distinct
  end

  def categories
    self.collection.categories
  end

  def supports_document_sets
    false
  end

  def notes
    Note.where(work_id: self.works.ids).order('created_at DESC')
  end

  def deeds
    self.collection.deeds.where(work_id: self.works.ids).joins(:work).includes(:work).reorder('deeds.created_at DESC')
  end

  def restricted
    !self.is_public
  end

  def active?
    self.collection.active?
  end

  def footer_block
    self.collection.footer_block
  end

  def help
    self.collection.help
  end

  def link_help
    self.collection.link_help
  end

  def voice_recognition
    self.collection.voice_recognition
  end

  def language
    self.collection.language
  end

  def text_language
    self.collection.text_language
  end

  def field_based
    self.collection.field_based
  end

  def picture_url(thumb=nil)
    if self.picture.blank?
      self.collection.picture.url(thumb)
    else
      self.picture.url(thumb)
    end
  end

  def transcription_fields
    self.collection.transcription_fields
  end

  def metadata_fields
    self.collection.metadata_fields
  end

  def description_instructions
    self.collection.description_instructions
  end

  def text_entry?
    self.collection.text_entry?
  end

  def metadata_entry?
    self.collection.metadata_entry?
  end

  def set_next_untranscribed_page
    first_work = works.order_by_incomplete.first
    first_page = first_work.nil? ? nil : first_work.next_untranscribed_page
    page_id = first_page.nil? ? nil : first_page.id

    update_columns(next_untranscribed_page_id: page_id)
  end

  def find_next_untranscribed_page_for_user(user)
    return nil unless has_untranscribed_pages?
    return next_untranscribed_page if user.can_transcribe?(next_untranscribed_page.work)

    public = works
      .where.not(next_untranscribed_page_id: nil)
      .unrestricted
      .order_by_incomplete

    return public.first.next_untranscribed_page unless public.empty?

    private = works
      .where.not(next_untranscribed_page_id: nil)
      .restricted
      .order_by_incomplete

    wk = private.find{ |w| user.can_transcribe?(w) }

    wk.nil? ? nil : wk.next_untranscribed_page
  end

  def has_untranscribed_pages?
    next_untranscribed_page.present?
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
    self.works.where("title LIKE ? OR searchable_metadata like ?", "%#{search}%", "%#{search}%")
  end

  def search_collection_works(search)
    self.collection.search_works(search)
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

  def facets_enabled?
    self.collection.facets_enabled?
  end

  def sc_collection # association does not exist for document sets
    nil
  end

  def api_access 
    collection.api_access
  end

  def alphabetize_works
    self.collection.alphabetize_works
  end

  def institution_signature
    self.collection.institution_signature
  end

  def most_recent_deed_created_at
    self.collection.most_recent_deed_created_at
  end

  def user_help
    self.collection.owner.help
  end

  public :user_help
end
