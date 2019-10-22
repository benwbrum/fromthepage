class DocumentSet < ActiveRecord::Base
  include DocumentSetStatistic

  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]
  
  attr_accessible :title, :description, :collection_id, :picture, :is_public, :slug, :pct_completed, :works_count

  mount_uploader :picture, PictureUploader

  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  belongs_to :collection
  belongs_to :next_untranscribed_page, foreign_key: 'next_untranscribed_page_id', class_name: "Page"

  has_many :pages, through: :works

  has_many :document_set_works
  has_many :works, through: :document_set_works

  has_and_belongs_to_many :collaborators, :class_name => 'User', :join_table => :document_set_collaborators
  
  after_save :set_next_untranscribed_page

  validates :title, presence: true, length: { minimum: 3, maximum: 255 }

  scope :unrestricted, -> { where(is_public: true)}
  scope :restricted, -> { where(is_public: false)}
  scope :carousel, -> {where(pct_completed: [nil, 1..90]).joins(:collection).where.not(collections: {picture: nil}).where.not(description: [nil, '']).where(is_public: true).reorder("RAND()")}
  scope :has_intro_block, -> { where.not(description: [nil, '']) }
  scope :not_near_complete, -> { where(pct_completed: [nil, 0..90]) }
  scope :not_empty, -> { where.not(works_count: [0, nil]) }
  
  scope :sample, -> (sample_size = 5) do
    carousel
    reorder("RAND()") unless sample_size > 1
    limit(sample_size).reorder("RAND()")
  end

  def show_to?(user)
    self.is_public? || (user && user.like_owner?(self)) || (user && user.collaborator?(self))
  end

  def intro_block
    self.description
  end
  
  def hide_completed
    self.collection.hide_completed
  end

  def subjects_disabled
    self.collection.subjects_disabled
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
    Note.where(work_id: self.works.ids)
  end

  def deeds
    self.collection.deeds.where(work_id: self.works.ids)
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
      self.collection.picture.url(:thumb)
    else
      self.picture.url(:thumb)
    end
  end

  def transcription_fields
    self.collection.transcription_fields
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
    self.works.where("title LIKE ?", "%#{search}%")
  end

  def search_collection_works(search)
    self.collection.works.where("title LIKE ?", "%#{search}%")
  end

  def self.search(search)
    where("title LIKE ? OR slug LIKE ?", "%#{search}%", "%#{search}%")
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
end
