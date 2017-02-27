require 'search_translator'
class Page < ActiveRecord::Base

  include XmlSourceProcessor

  before_update :process_source
  before_update :populate_search
  validate :validate_source, :validate_source_translation

  belongs_to :work
  acts_as_list :scope => :work

  has_many :page_article_links, :dependent => :destroy
  has_many :articles, :through => :page_article_links
  has_many :page_versions, -> { order 'page_version DESC' }, :dependent => :destroy

  belongs_to :current_version, :class_name => 'PageVersion', :foreign_key => 'page_version_id'

  has_and_belongs_to_many :sections

  has_many :notes, -> { order 'created_at' }, :dependent => :destroy
  has_one :ia_leaf
  has_one :omeka_file
  has_one :sc_canvas
  has_many :table_cells, -> { order 'section_id, row, header' }
  has_many :tex_figures

  after_save :create_version
  after_save :update_sections_and_tables
  after_save :update_tex_figures
  after_initialize :defaults
  after_destroy :update_work_stats
  after_destroy :delete_deeds

  attr_accessible :title
  attr_accessible :source_text
  attr_accessible :source_translation
  attr_accessible :status
  
  module TEXT_TYPE
    TRANSCRIPTION = 'transcription'
    TRANSLATION = 'translation'
  end

  STATUS_BLANK = 'blank'
  STATUS_INCOMPLETE = 'incomplete'
  STATUS_UNCORRECTED_OCR = 'raw_ocr'
  STATUS_INCOMPLETE_OCR = 'part_ocr'
  STATUS_INCOMPLETE_TRANSLATION = 'part_xlatn'

  STATUSES =
  { "Blank/Nothing to Transcribe" => STATUS_BLANK,
    "Incomplete Transcription" => STATUS_INCOMPLETE,
    "Incomplete Correction" => STATUS_INCOMPLETE_OCR,
    "Uncorrected OCR" => STATUS_UNCORRECTED_OCR,
    "Incomplete Translation" => STATUS_INCOMPLETE_TRANSLATION }
  STATUS_HELP = {
    STATUS_BLANK => "Mark the page as blank if there is no meaningful text on this page.",
    STATUS_INCOMPLETE => "Mark the page as incomplete to list it for review by others.",
  }

  # tested
  def collection
    work.collection
  end

  def articles_with_text
    articles :conditions => ['articles.source_text is not null']
  end

  def defaults
    if self[:title].blank?
      self[:title] = "Untitled Page #{self[:position]}"
    end
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

  def canonical_facsimile_url

    if self.ia_leaf
      self.ia_leaf.facsimile_url
    elsif self.sc_canvas
      self.sc_canvas.facsimile_url      
    else
      base_image
    end
  end

  def base_image
    self[:base_image] || ""
  end

  def shrink_factor
    self[:shrink_factor] || 0
  end


  def scaled_image(factor = 2)
    if 0 == factor
      self.base_image
    else
      self.base_image.sub(/.jpg/, "_#{factor}.jpg")
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
    version.source_translation = self.source_translation
    version.xml_translation = self.xml_translation
    version.user = User.current_user
    
    # now do the complicated version update thing
    version.work_version = self.work.transcription_version
    self.work.increment!(:transcription_version)

    previous_version = PageVersion.where("page_id = ?", self.id).order("page_version DESC").first
    if previous_version
      version.page_version = previous_version.page_version + 1
    end
    version.save!
  end

  def update_sections_and_tables
    if @sections
      self.sections.each { |s| s.delete }
      self.table_cells.each { |c| c.delete }
  #    binding.pry
      
      @sections.each do |section|
        section.pages << self
        section.work = self.work
        section.save!
      end
      
      self.table_cells.each { |c| c.delete }
      @tables.each do |table|
        table[:rows].each_with_index do |row, rownum|
          row.each_with_index do |cell, cell_index|
            tc = TableCell.new(:row => rownum,
              :content => cell,
              :header => table[:header][cell_index] )
            tc.work = self.work
            tc.page = self
            tc.section = table[:section]
            tc.save!
          end
        end
      end
      
    end
  end

  def submit_background_processes
    TexFigure.submit_background_process(self.id)
  end
  
  def update_tex_figures
    self.tex_figures.each do |tex_figure|
      if tex_figure.changed?
        tex_figure.save!
      end
    end
  end

  # This deletes all graphs within associated articles
  # It should be called twice whenever a page is changed
  # once to reset the previous links, once to reset new links
  def clear_article_graphs
    Article.where("id in (select article_id "+
                       "       from page_article_links "+
                       "       where page_id = #{self.id})").update_all(:graph_image=>nil)
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

  def populate_search
    self.search_text = SearchTranslator.search_text_from_xml(self.xml_text, self.xml_translation)
  end


  #######################
  # XML Source support
  #######################

  def clear_links(text_type)
    # first use the existing links to blank the graphs
    self.clear_article_graphs
    # clear out the existing links to this page
    PageArticleLink.delete_all("page_id = #{self.id} and text_type = '#{text_type}'")
  end

  # tested
  def create_link(article, display_text, text_type)
    link = PageArticleLink.new(page: self, article: article,
                               display_text: display_text, text_type: text_type)
    link.save!
    return link.id
  end

  def thumbnail_filename
    filename=self.base_image
    ext=File.extname(filename)
    filename.sub("#{ext}","_thumb#{ext}")
  end

private
  def generate_thumbnail
    image = Magick::ImageList.new(self[:base_image])
    factor = 100.to_f / self[:base_height].to_f
    image.thumbnail!(factor)
    image.write(thumbnail_filename)
    image = nil
  end

  def update_work_stats
    if self.work
      self.work.work_statistic.recalculate
    end
  end

  def delete_deeds
    Deed.where(page_id: self.id).destroy_all
  end

end
