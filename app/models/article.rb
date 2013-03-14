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
  before_update :process_source

  validates_presence_of :title

  has_and_belongs_to_many :categories, :uniq => true
  belongs_to :collection
  has_many(:target_article_links, 
           { :foreign_key => "target_article_id", 
             :class_name => 'ArticleArticleLink', 
             :include => [:source_article], 
             :order => "articles.title ASC"})
  has_many(:source_article_links, 
           { :foreign_key => "source_article_id", 
             :class_name => 'ArticleArticleLink' })
  has_many(:page_article_links, 
           { :include => [:page], 
             :order => "pages.work_id, pages.position ASC" })

  has_many :pages, :through => :page_article_links, :order => "pages.work_id, pages.position ASC"

  has_many :article_versions, :order => :version

  
  after_save :create_version

  @title_dirty = false

  def title=(title)
    @title_dirty = true
    super
  end


  #######################
  # Related Articles 
  #######################
  def related_article_ranks

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
      # @collection.articles.find(:all, :conditions => ["title like ?", "%#{word}%"] )
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
  # tests
  def clear_links
    # clear out the existing links to this page
    ArticleArticleLink.delete_all("source_article_id = #{self.id}")     
  end

  # tested
  def create_link(article, display_text)
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
    if !@text_dirty or !@title_dirty
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

    previous_version = 
      ArticleVersion.find(:all, :conditions => ["article_id = ?", self.id],
                       :order => "version DESC")
    #       ArticleVersion.find(:first, 
    #                        :conditions => ["article_id = ?", self.id],
    #                        :order => "version DESC")
    if previous_version.first
      version.version = previous_version.first.version + 1
    end
    version.save!      
  end
end

