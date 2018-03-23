class DocumentSet < ActiveRecord::Base
  include DocumentSetStatistic

  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]
  
  attr_accessible :title, :description, :collection_id, :picture, :is_public, :slug, :pct_completed

  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  belongs_to :collection
  has_and_belongs_to_many :works
  has_and_belongs_to_many :collaborators, :class_name => 'User', :join_table => :document_set_collaborators
  
  validates :title, presence: true, length: { minimum: 3, maximum: 255 }

  scope :unrestricted, -> { where(is_public: true)}
  scope :carousel, -> {where(pct_completed: [nil, 1..90]).joins(:collection).where.not(collections: {picture: nil}).where.not(description: [nil, '']).where(is_public: true).reorder("RAND()")}

  def show_to?(user)
    self.is_public? || (user && user.collaborator?(self)) || self.collection.show_to?(user)
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

  def picture
    self.collection.picture
  end

  def picture_url(thumb=nil)
    self.collection.picture_url(:thumb)
  end

  def transcription_fields
    self.collection.transcription_fields
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

end
