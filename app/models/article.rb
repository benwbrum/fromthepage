#    create_table :articles do |t|
#      # t.column :name, :string
#      t.column :title, :string
#      t.column :source_text, :text
#      # automated stuff
#      t.column :created_on, :datetime
#      t.column :lock_version, :integer, :default => 0
#    end
# == Schema Information
#
# Table name: articles
#
#  id            :integer          not null, primary key
#  created_on    :datetime
#  graph_image   :string(255)
#  latitude      :decimal(7, 5)
#  lock_version  :integer          default(0)
#  longitude     :decimal(8, 5)
#  pages_count   :integer          default(0)
#  provenance    :string(255)
#  source_text   :text(16777215)
#  title         :string(255)
#  uri           :string(255)
#  xml_text      :text(16777215)
#  collection_id :integer
#  created_by_id :integer
#
# Indexes
#
#  fk_rails_35e2f292e3              (created_by_id)
#  index_articles_on_collection_id  (collection_id)
#
class Article < ApplicationRecord

  include XmlSourceProcessor
  # include ActiveModel::Dirty

  before_save :process_source

  validates :title, presence: true

  validates :latitude, allow_blank: true, numericality: { less_than_or_equal_to: 90, greater_than_or_equal_to: -90 }
  validates :longitude, allow_blank: true, numericality: { less_than_or_equal_to: 180, greater_than_or_equal_to: -180 }

  has_and_belongs_to_many :categories, -> { distinct }
  belongs_to :collection, optional: true
  has_many(:target_article_links, foreign_key: 'target_article_id', class_name: 'ArticleArticleLink')
  scope :target_article_links, -> { include 'source_article' }
  scope :target_article_links, -> { order 'articles.title ASC' }

  has_many(:source_article_links, foreign_key: 'source_article_id', class_name: 'ArticleArticleLink')
  has_many(:page_article_links)
  scope :page_article_links, -> { includes(:page) }
  scope :page_article_links, -> { order('pages.work_id, pages.position ASC') }

  scope :pages_for_this_article, -> { order('pages.work_id, pages.position ASC').includes(:pages) }

  has_many :pages, through: :page_article_links, counter_cache: true

  has_many :article_versions, -> { order 'version DESC' }, dependent: :destroy

  after_save :create_version

  def link_list
    page_article_links.includes(:page).order('pages.work_id, pages.title')
  end

  # needed for document sets to correctly display articles
  def show_links(collection)
    page_article_links.includes(:page).where(pages: { work_id: collection.works.ids })
  end

  def page_list
    pages.order('pages.work_id, pages.position')
  end

  def source_text
    self[:source_text] || ''
  end

  def self.delete_orphan_articles
    # don't delete orphan articles with contents
    Article.delete_all('source_text IS NULL AND id NOT IN (select article_id from page_article_links)')
  end

  #######################
  # Related Articles
  #######################
  def related_article_ranks
  end

  def gis_enabled?
    categories.where(gis_enabled: true).present?
  end

  #######################
  # De-Dup Support
  #######################
  # tested
  def possible_duplicates
    logger.debug '------------------------------'
    logger.debug 'article.possible_duplicates'
    # take each element of this article name
    words = title.tr(',.', ' ').split
    # sort it by word length, longest to shortest
    words.keep_if { |word| word.match(/\w\w/) }
    words.sort! { |x, y| x.length <=> y.length }
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
        collection.articles.where('id <> ? AND title like ?', id, "%#{word}%")
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
    logger.debug('at the end of article.possible_duplicates')
    logger.debug('--------------------------------------')
    all_matches
  end

  #######################
  # XML Source support
  #######################
  # tested
  def clear_links(_type = 'does_not_apply')
    # clear out the existing links to this page
    return unless id

    ArticleArticleLink.where("source_article_id = #{id}").delete_all
  end

  # tested
  def create_link(article, display_text, _text_type)
    link = ArticleArticleLink.new
    link.source_article = self
    link.target_article = article
    link.display_text = display_text
    link.save!
    link.id
  end

  #######################
  # Version support
  #######################
  # tested
  def create_version
    return unless saved_change_to_title? || saved_change_to_source_text?

    version = ArticleVersion.new
    # copy article data
    version.title = title
    version.xml_text = xml_text
    version.source_text = source_text
    # set foreign keys
    version.article = self
    version.user = User.current_user

    # now do the complicated version update thing

    previous_version = ArticleVersion.where(article_id: id).order('version DESC').all
    version.version = previous_version.first.version + 1 if previous_version.first
    version.save!
  end

  # Retrieve the hierarchy of categories for the article as a formatted string
  def formatted_category_hierarchy
    hierarchy_titles = categories.flat_map { |category| ancestors_and_self(category) }.pluck(:title)
    hierarchy_titles.reverse.join(' -- ')
  end

  private

  def ancestors_and_self(category)
    ancestors = category.ancestors.reverse

    [category] + ancestors
  end

end
