class Work < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]

  has_many :pages, -> { order 'position' }, :dependent => :destroy
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  belongs_to :collection
  has_many :deeds, -> { order 'created_at DESC' }, :dependent => :destroy
  has_one :ia_work, :dependent => :destroy
  has_one :omeka_item, :dependent => :destroy
  has_one :sc_manifest, :dependent => :destroy
  has_one :work_statistic, :dependent => :destroy
  has_many :sections, -> { order 'position' }, :dependent => :destroy
  has_many :table_cells, -> { order 'page_id, row, header' }, :dependent => :destroy

  has_and_belongs_to_many :scribes, :class_name => 'User', :join_table => :transcribe_authorizations
  has_and_belongs_to_many :document_sets

  after_save :update_statistic
  after_destroy :cleanup_images

  attr_accessible :title,
                  :author,
                  :description,
                  :collection_id,
                  :physical_description,
                  :document_history,
                  :permission_description,
                  :location_of_composition,
                  :transcription_conventions,
                  :supports_translation,
                  :translation_instructions,
                  :scribes_can_edit_titles,
                  :restrict_scribes,
                  :pages_are_meaningful,
                  :slug,
                  :picture,
                  :featured_page

  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :slug, uniqueness: true

  mount_uploader :picture, PictureUploader

  scope :unrestricted, -> { where(restrict_scribes: false)}

  module TitleStyle
    REPLACE = 'REPLACE'
    
    PAGE_ARABIC = "Page #{REPLACE}"
    PAGE_ROMAN = "Page #{REPLACE}"
    ENVELOPE = "Envelope (#{REPLACE})"
    COVER = 'Cover (#{REPLACE})'
    ENCLOSURE = 'Enclosure REPLACE'
    DEFAULT = PAGE_ARABIC
    
    def self.render(style, number)
      style.sub(REPLACE, number.to_s)
    end
    
    def self.style_from_prior_title(title)
      PAGE_ARABIC
    end
    def self.number_from_prior_title(style, title)
      regex_string = style.sub('REPLACE', "(\\d+)")
      md = title.match(/#{regex_string}/)
      
      if md
        md.captures.first
      else
        nil
      end
    end
  end
  
  def suggest_next_page_title
    if self.pages.count == 0
      TitleStyle::render(TitleStyle::DEFAULT, 1)    
    else
      prior_title = self.pages.last.title
      style = TitleStyle::style_from_prior_title(prior_title)
      number = TitleStyle::number_from_prior_title(style, prior_title)      
      
      next_number = number ? number.to_i + 1 : self.pages.count + 1
      
      TitleStyle::render(style, next_number)
    end
  end

  def revert
  end

  def articles
    Article.joins(:page_article_links).where(page_article_links: {page_id: self.pages.ids}).distinct
  end

  # TODO make not awful
  def reviews
    my_reviews = []
    for page in self.pages
      for comment in page.comments
        my_reviews << comment if comment.comment_type == 'review'
      end
    end
    return my_reviews
  end

  # TODO make not awful (denormalize work_id, collection_id; use legitimate finds)
  def recent_annotations
    my_annotations = []
    for page in self.pages
      for comment in page.comments
        my_annotations << comment if comment.comment_type == 'annotation'
      end
    end
    my_annotations.sort! { |a,b| b.created_at <=> a.created_at }
    return my_annotations[0..9]
  end

  def update_statistic
    p 'update_statistic start'
    unless self.work_statistic
      self.work_statistic = WorkStatistic.new
    end
    self.work_statistic.recalculate
    p 'update_statistic finish'
  end

  def set_transcription_conventions
    if self.transcription_conventions.present?
      self.transcription_conventions
    else
      self.collection.transcription_conventions
    end
  end

  def cleanup_images
    new_dir_name = File.join(Rails.root, "public", "images", "uploaded", self.id.to_s)
    if Dir.exist?(new_dir_name)
      Dir.glob(File.join(new_dir_name, "*")){|f| File.delete(f)}
      Dir.rmdir(new_dir_name)
    end

  end

  def thumbnail
    if !self.picture.blank?
      self.picture_url(:thumb)
    else
      unless self.pages.count == 0
        if self.featured_page.nil?
          set_featured_page
        end
        featured_page = Page.find_by(id: self.featured_page)
        featured_page.thumbnail_url
      else
        return nil
      end
    end
  end

  def normalize_friendly_id(string)
    string = string.truncate(230, separator: ' ', omission: '')
    super.gsub('_', '-')
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

  def set_featured_page
      num = (self.pages.count/3).round
      page = self.pages.offset(num).first
      self.update_columns(featured_page: page.id)
  end

end