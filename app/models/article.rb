#    create_table :articles do |t|
#      # t.column :name, :string
#      t.column :title, :string
#      t.column :source_text, :text
#      # automated stuff
#      t.column :created_on, :datetime
#      t.column :lock_version, :integer, :default => 0
#    end
class Article < ActiveRecord::Base
  include XmlSourceProcessor
  #include ActiveModel::Dirty

  before_update :process_source

  validates_presence_of :title

  validates :latitude, allow_blank: true, numericality: { less_than_or_equal_to: 90, greater_than_or_equal_to: -90}
  validates :longitude, allow_blank: true, numericality: { less_than_or_equal_to: 180, greater_than_or_equal_to: -180}


  has_and_belongs_to_many :categories, -> { uniq }
  belongs_to :collection
  has_many(:target_article_links, { :foreign_key => "target_article_id", :class_name => 'ArticleArticleLink'})
  scope :target_article_links, -> { include 'source_article' }
  scope :target_article_links, -> { order "articles.title ASC" }

  has_many(:source_article_links, { :foreign_key => "source_article_id", :class_name => 'ArticleArticleLink' })
  has_many(:page_article_links)
  scope :page_article_links, -> { includes(:page) }
  scope :page_article_links, -> { order("pages.work_id, pages.position ASC") }

  scope :pages_for_this_article, -> { order("pages.work_id, pages.position ASC").includes(:pages)}

  has_many :pages, :through => :page_article_links

  has_many :article_versions, -> { order 'version DESC' }, dependent: :destroy

  after_save :create_version

  attr_accessible :title, :latitude, :longitude, :uri
  attr_accessible :source_text

  def link_list
    self.page_article_links.includes(:page).order("pages.work_id, pages.title")
  end

  #needed for document sets to correctly display articles
  def show_links(collection)
    self.page_article_links.includes(:page).where(pages: {work_id: collection.works.ids}).group(:text_type, :page_id).order("pages.work_id, pages.title")
  end

  def page_list
    self.pages.order("pages.work_id, pages.position")
  end

  def source_text
    self[:source_text] || ''
  end


  def self.delete_orphan_articles
    # don't delete orphan articles with contents
    Article.delete_all("source_text IS NULL AND id NOT IN (select article_id from page_article_links)")
  end

  #######################
  # Related Articles
  #######################
  def related_article_ranks

  end
  
  def gis_enabled?
    self.categories.where(:gis_enabled => true).present?
  end

  #######################
  # De-Dup Support
  #######################
  # tested
  def possible_duplicates
    logger.debug "------------------------------"
    logger.debug "article.possible_duplicates"
    # take each element of this article name
    words = self.title.tr(',.', ' ').split(' ')
    # sort it by word length, longest to shortest
    words.sort! { |x,y| x.length <=> y.length }
    words.reverse!
    # for each word
    all_matches = []
    logger.debug("DEBUG: matching #{words}")
    words.each do |word|
      # find articles in the same collection
      # whose title contains that word
      # logger.debug("the word is #{word}")

      # logger.debug("@collection.id: #{self.collection.id}")

      current_matches =
        self.collection.articles.where("id <> ? AND title like ?", self.id, "%#{word}%" )
      # current_matches.delete self
      #      logger.debug("DEBUG: #{current_matches.size} matches for #{word}")
      #    keep sort order for new words (append to previous list)
      #    if there's a match with the previous list, bump up that
      #    article
      matches_in_common = all_matches & current_matches
      old_matches = all_matches - current_matches
      new_matches = current_matches - matches_in_common
      # merge with articles for previous words
      all_matches = matches_in_common + old_matches + new_matches
    end
    #    logger.debug("DEBUG: found #{all_matches.size} matches:")
    #    logger.debug("DEBUG: #{all_matches.inspect}")
    logger.debug("at the end of article.possible_duplicates")
    logger.debug("--------------------------------------")
    return all_matches
  end


  #######################
  # XML Source support
  #######################
  # tested
  def clear_links(type='does_not_apply')
    # clear out the existing links to this page
    ArticleArticleLink.delete_all("source_article_id = #{self.id}")
  end

  # tested
  def create_link(article, display_text, text_type)
    link = ArticleArticleLink.new
    link.source_article = self
    link.target_article = article
    link.display_text = display_text
    link.save!
    return link.id
  end

  #######################
  # Version support
  #######################
  # tested
  def create_version

  unless self.title_changed? || self.source_text_changed?
    return
  end

    version = ArticleVersion.new
    # copy article data
    version.title = self.title
    version.xml_text = self.xml_text
    version.source_text = self.source_text
    # set foreign keys
    version.article = self
    version.user = User.current_user

    # now do the complicated version update thing

    previous_version = ArticleVersion.where(["article_id = ?", self.id]).order("version DESC").all
    if previous_version.first
      version.version = previous_version.first.version + 1
    end
    version.save!
  end
end

