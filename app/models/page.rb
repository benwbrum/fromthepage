# t.column :title, :string, :limit => 255
# # transcription source (rudimentary for this version)
# t.column :transcription, :text
# # image info
# t.column :base_image, :string, :limit => 255
# t.column :base_width, :integer
# t.column :base_height, :integer
# t.column :shrink_factor, :integer
# # foreign keys
# t.column :work_id, :integer
# # automated stuff
# t.column :created_on, :datetime
# t.column :position, :integer
# t.column :lock_version, :integer, :default => 0

class Page < ActiveRecord::Base
  require 'RMagick'
  
  include XmlSourceProcessor
  before_update :process_source
  
  belongs_to :work
  acts_as_list :scope => :work

  has_many :page_article_links
  has_many :articles, :through => :page_article_links
  has_many :page_versions, :order => 'page_version DESC'

  belongs_to :current_version, :class_name => 'PageVersion', :foreign_key => 'page_version_id'

  #acts_as_restful_commentable
  has_many :notes, :order => :created_at
  has_one :ia_leaf
  
  after_save :create_version
  
  STATUS_BLANK = 'blank'
  STATUS_INCOMPLETE = 'incomplete'
 
  STATUSES = { "Blank/Nothing to Transcribe" => STATUS_BLANK, "Incomplete Transcription" => STATUS_INCOMPLETE } 
  STATUS_HELP = "Mark a page as blank if there is nothing to be transcribed on this page.  Mark a page as incomplete to list it for review by others."

  # tested
  def collection
    work.collection
  end
  
  def articles_with_text
    articles :conditions => ['articles.source_text is not null']
  end

  def title
    self[:title].blank? ? "untitled page #{self[:position]}" : self[:title]
  end


  # we need a short pagename for index entries
  # in this case this will refer to an entry without
  # superfluous information that would be redundant
  # within the context of a chapter
  # TODO: convert to use a regex stored on the work
  def title_for_print_index
    if title.match(/\w+\W+\w+\W+(\w+)/)
      $1
    else
      title
    end
  end

  # extract a chapter name from the page title
  # TODO: convert to use a regex stored on the work
  def chapter_for_print
    parts = title.split
    if parts.length > 1
      parts[1]
    else
      title
    end
  end

  def scaled_image(factor = 2)
    if 0 == factor
      self[:base_image]
    else
      self[:base_image].sub(/.jpg/, "_#{factor}.jpg")
    end
  end
  
  # Returns the thumbnail filename
  # creates the image if it's not present
  def thumbnail_image
    if self.ia_leaf 
      return nil
    end
    if !File.exists?(thumbnail_filename())
      if File.exists? self.base_image
        generate_thumbnail      
      end
    end
    return thumbnail_filename 
  end

  # tested
  def create_version
    version = PageVersion.new
    version.page = self
    version.title = self.title
    version.transcription = self.source_text
    version.xml_transcription = self.xml_text
    version.user = User.current_user
    
    # now do the complicated version update thing
    version.work_version = self.work.transcription_version
    self.work.increment!(:transcription_version)    

    previous_version = 
      PageVersion.find(:first, 
                       :conditions => ["page_id = ?", self.id],
                       :order => "page_version DESC")
    if previous_version
      version.page_version = previous_version.page_version + 1
    end
    version.save!      
  end
  
  # This deletes all graphs within associated articles
  # It should be called twice whenever a page is changed
  # once to reset the previous links, once to reset new links
  def clear_article_graphs
    Article.update_all('graph_image=NULL', 
                       "id in (select article_id "+
                       "       from page_article_links "+
                       "       where page_id = #{self.id})")
  end
=begin
Here is the ActiveRecord call (with sql in it) in method clear_article_graphs:
Article.update_all('graph_image=NULL', "id in (select article_id from page_article_links  where page_id = 1)")
It produces this SQL:
UPDATE `articles` SET graph_image=NULL WHERE (id in (select article_id from page_article_links where page_id = 1))

There is a more idiomatic ActiveRecord call:
Article.update_all('graph_image=NULL', :id => PageArticleLink.select(:article_id).where('page_id = ?', 1))
it produces this sql:
UPDATE `articles` SET graph_image=NULL WHERE `articles`.`id` IN (SELECT article_id FROM `page_article_links` WHERE (page_id = 1))
=end
  
  #######################
  # XML Source support
  #######################
  
  def clear_links
    # first use the existing links to blank the graphs
    self.clear_article_graphs
    # clear out the existing links to this page
    PageArticleLink.delete_all("page_id = #{self.id}")     
  end

  # tested
  def create_link(article, display_text)
    link = PageArticleLink.new(:page => self,
                               :article => article,
                               :display_text => display_text)
    link.save!
    
    return link.id        
  end

private
  def thumbnail_filename
    self[:base_image].sub(/.jpg/, "_thumb.jpg")
  end

  def generate_thumbnail
    image = Magick::ImageList.new(self[:base_image])
    factor = 100.to_f / self[:base_height].to_f
    image.thumbnail!(factor)
    image.write(thumbnail_filename)
    image = nil
  end

end
