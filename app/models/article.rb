# == Schema Information
#
# Table name: articles
#
#  id               :integer          not null, primary key
#  begun            :string(255)
#  bibliography     :text(65535)
#  birth_date       :string(255)
#  created_on       :datetime
#  death_date       :string(255)
#  ended            :string(255)
#  graph_image      :string(255)
#  latitude         :decimal(7, 5)
#  lock_version     :integer          default(0)
#  longitude        :decimal(8, 5)
#  pages_count      :integer          default(0)
#  provenance       :string(255)
#  race_description :string(255)
#  sex              :string(255)
#  short_summary    :string(255)
#  source_text      :text(16777215)
#  title            :string(255)
#  uri              :string(255)
#  xml_text         :text(16777215)
#  collection_id    :integer
#  created_by_id    :integer
#
# Indexes
#
#  fk_rails_35e2f292e3              (created_by_id)
#  index_articles_on_collection_id  (collection_id)
#
class Article < ApplicationRecord
  include XmlSourceProcessor
  include EdtfDate

  #include ActiveModel::Dirty

  before_save :process_source

  validates_presence_of :title

  validates :latitude, allow_blank: true, numericality: { less_than_or_equal_to: 90, greater_than_or_equal_to: -90}
  validates :longitude, allow_blank: true, numericality: { less_than_or_equal_to: 180, greater_than_or_equal_to: -180}

  has_many :articles_categories
  has_many :categories, -> { distinct }, through: :articles_categories

  belongs_to :collection, optional: true

  has_many :target_article_links, foreign_key: 'target_article_id', class_name: 'ArticleArticleLink'
  scope :target_article_links, -> { include 'source_article' }
  scope :target_article_links, -> { order "articles.title ASC" }

  has_many :source_article_links, foreign_key: 'source_article_id', class_name: 'ArticleArticleLink'
  has_many :page_article_links
  scope :page_article_links, -> { includes(:page) }
  scope :page_article_links, -> { order("pages.work_id, pages.position ASC") }

  scope :pages_for_this_article, -> { order("pages.work_id, pages.position ASC").includes(:pages) }

  has_many :pages, through: :page_article_links
  has_many :works, through: :page_article_links

  has_many :article_versions, -> { order 'version DESC' }, dependent: :destroy

  after_save :create_version

  edtf_date_attribute :birth_date
  edtf_date_attribute :death_date
  edtf_date_attribute :begun
  edtf_date_attribute :ended

  update_index('articles', if: -> { ELASTIC_ENABLED && !destroyed? }) { self }
  after_destroy :handle_index_deletion

  def self.es_search(query:, user: nil, is_public: true)
    blocked_collections = []
    collection_collabs = []
    docset_collabs = []

    if user.present?
      blocked_collections = user.blocked_collections.pluck(:id)
      collection_collabs  = user.collection_collaborations.pluck(:id)
      collection_collabs += user.owned_collections.pluck(:id)
      docset_collabs      = user.document_set_collaborations.pluck(:id)
    end

    search_fields = [
      'title^2',
      'title.no_underscores^1.3'
    ]

    ArticlesIndex.query(
      bool: {
        must: {
          simple_query_string: {
            query: query,
            fields: [
              'title^2',
              'title.no_underscores^1.3'
            ]
          }
        },
        filter: [
          bool: {
            must_not: [
              { terms: { collection_id: blocked_collections } }
            ],
            # At least one of the following must be true
            should: [
              { term: { is_public: is_public } },
              { term: { owner_user_id: user&.id || -1 } },
              { terms: { collection_id: collection_collabs } },
              { terms: { docset_id: docset_collabs } }
            ],
            minimum_should_match: 1
          }
        ]
      }
    )
  end

  def link_list
    self.page_article_links.includes(:page).order("pages.work_id, pages.title")
  end

  # Needed for document sets to correctly display articles
  def show_links(collection)
    self.page_article_links.includes(:page).where(pages: {work_id: collection.works.ids})
  end

  def page_list
    self.pages.order("pages.work_id, pages.position")
  end

  def source_text
    self[:source_text] || ''
  end

  def self.delete_orphan_articles
    # don't delete orphan articles with contents
    Article.where(provenance: nil).
      where('source_text IS NULL AND id NOT IN (SELECT article_id FROM page_article_links)').destroy_all
  end

  #######################
  # Related Articles
  #######################
  def related_article_ranks

  end

  def gis_enabled?
    self.categories.where(:gis_enabled => true).present?
  end

  def bio_fields_enabled?
    self.categories.where(:bio_fields_enabled => true).present?
  end

  def org_fields_enabled?
    self.categories.where(:org_fields_enabled => true).present?
  end

  def clear_relationship_graph
    File.unlink(d3js_file) if File.exists?(d3js_file)
  end

  def d3js_file
    "#{Rails.root}/public/images/working/dot/#{self.id}.d3.js"
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
    words.keep_if { |word| word.match(/\w\w/) }
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
    if self.id
      ArticleArticleLink.where("source_article_id = #{self.id}").destroy_all
    end
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

    unless self.saved_change_to_title? || self.saved_change_to_source_text?
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

  def handle_index_deletion
    return unless ELASTIC_ENABLED

    Chewy.client.delete(
      index: ArticlesIndex.index_name,
      id: id
    )
  rescue StandardError => _e
    # Make sure it does not fail
  end
end
