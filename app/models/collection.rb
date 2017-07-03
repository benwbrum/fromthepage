require 'csv'

class Collection < ActiveRecord::Base
  include CollectionStatistic
  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]

  has_many :works, -> { order 'title' }, :dependent => :destroy #, :order => :position
  has_many :notes, -> { order 'created_at DESC' }, :dependent => :destroy
  has_many :articles, :dependent => :destroy
  has_many :document_sets, -> { order 'title' }, :dependent => :destroy
  has_many :categories, -> { order 'title' }
  has_many :deeds, -> { order 'created_at DESC' }, :dependent => :destroy
  has_one :sc_collection, :dependent => :destroy

  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  has_and_belongs_to_many :owners, :class_name => 'User', :join_table => :collection_owners
  attr_accessible :title, :intro_block, :footer_block, :picture, :subjects_disabled, :transcription_conventions, :slug
#  attr_accessor :picture

  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  
  before_create :set_transcription_conventions
  after_save :create_categories

  mount_uploader :picture, PictureUploader

  scope :order_by_recent_activity, -> { joins(:deeds).order('deeds.created_at DESC') }
  scope :unrestricted, -> { where(restricted: false)}

  def export_subjects_as_csv
    csv_string = CSV.generate(:force_quotes => true) do |csv|
      csv << %w{ Work_Title Page_Title Page_Position Page_URL Subject Text Category Category Category }
      self.works.each do |work|
        work.pages.includes(:page_article_links, articles: [:categories]).each do |page|
          page_url="http://localhost:3000/display/display_page?page_id=#{page.id}"
          page.page_article_links.each do |link|
            display_text = link.display_text.gsub("<lb/>", ' ').gsub("\n", "")
            article = link.article
            category_array = []
            article.categories.each do |category|
              category_array << category.title
            end
            csv << [work.title, page.title, page.position, page_url, link.article.title, display_text, category_array.sort].flatten
          end
        end
      end
    end
    csv_string
  end

  def show_to?(user)
    (!self.restricted && self.works.present?) || (user && user.like_owner?(self))
  end

  def create_categories
    #create two default categories
    category1 = Category.new(collection_id: self.id, title: "People")
    category1.save
    category2 = Category.new(collection_id: self.id, title: "Places")
    category2.save
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

  def blank_out_collection
    puts "Reset all data in the #{self.title} collection to blank"
    works = Work.where(collection_id: self.id)
    pages = Page.where(work_id: works.ids)

    #delete deeds for pages and articles (not work add deed)
    Deed.where(page_id: pages.ids).destroy_all
    Deed.where(article_id: self.articles.ids).destroy_all
    #delete articles
    Article.where(collection_id: self.id).destroy_all
    #delete categories (aside from the default)
    Category.where(collection_id: self.id).where.not(title: 'People').where.not(title: 'Places').destroy_all
    #delete notes
    Note.where(page_id: pages.ids).destroy_all
    #delete page_article_links
    PageArticleLink.where(page_id: pages.ids).destroy_all
    #update work transcription version
    works.each do |w|
      w.update_columns(transcription_version: 0)
    end
    #for each page, delete page versions, update all attributes, save
    pages.each do |p|
      p.page_versions.destroy_all
      p.update_columns(source_text: nil, base_image:nil, base_width: nil, base_height: nil, shrink_factor: nil, created_on: Time.now, lock_version: 0, xml_text: nil, status: nil, source_translation: nil, xml_translation: nil, translation_status: nil, search_text: "\n\n\n\n")
      p.save!
    end

    #fix user_id for page version (doesn't get set in this type of update)
    PageVersion.where(page_id: pages.ids).each do |v|
      v.user_id = self.owner.id
      v.save!
    end
    puts "#{self.title} collection has been reset"
  end

  protected
    def set_transcription_conventions
      unless self.transcription_conventions.present?
        self.transcription_conventions = "<p><b>Transcription Conventions</b>\n<ul><li><i>Spelling: </i>Use original spelling if possible.</li>\n <li><i>Capitalization: </i>Modernize for readability</li>\n<li><i>Punctuation: </i>Add modern periods, but don't add punctuation like commas and apostrophes.</li>\n<li><i>Line Breaks: </i>Hit <code>return</code> once after each line ends.  Two returns indicate a new paragraph, which is usually indentation  following the preceding sentence in the original.  The times at the end of each entry should get their own paragraph, since the software does not support indentation in the transcriptions.</li>\n <li><i>Illegible text: </i>Indicate illegible readings in single square brackets: <code>[Dr?]</code></li></ul></p>"
      end
    end

end