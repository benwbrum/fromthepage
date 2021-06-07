require 'search_translator'
class Page < ApplicationRecord
  ActiveRecord::Base.lock_optimistically = false

  include XmlSourceProcessor
  include ApplicationHelper

  before_update :validate_blank_page
  before_update :process_source
  before_update :populate_search
  validate :validate_source, :validate_source_translation

  belongs_to :work, optional: true
  acts_as_list :scope => :work

  has_many :page_article_links, :dependent => :destroy
  has_many :articles, :through => :page_article_links
  has_many :page_versions, -> { order 'page_version DESC' }, :dependent => :destroy

  belongs_to :current_version, :class_name => 'PageVersion', :foreign_key => 'page_version_id', optional: true

  has_and_belongs_to_many :sections

  has_many :notes, -> { order 'created_at' }, :dependent => :destroy
  has_one :ia_leaf, :dependent => :destroy
  has_one :sc_canvas, :dependent => :destroy
  has_many :table_cells, :dependent => :destroy
  has_many :tex_figures, :dependent => :destroy
  has_many :deeds, :dependent => :destroy

  after_save :create_version
  after_save :update_sections_and_tables
  after_save :update_tex_figures
  after_save do
    work.update_next_untranscribed_pages if self == work.next_untranscribed_page or work.next_untranscribed_page.nil?
  end

  after_initialize :defaults
  after_destroy :update_work_stats
  #after_destroy :delete_deeds
  after_destroy :update_featured_page, if: Proc.new {|page| page.work.featured_page == page.id}

  serialize :metadata, Hash

  scope :review, -> { where(status: 'review')}
  scope :translation_review, -> { where(translation_status: 'review')}
  scope :needs_transcription, -> { where(status: [nil, STATUS_INCOMPLETE])  }
  scope :needs_translation, -> { where(translation_status: nil)}
  scope :needs_index, -> { where.not(status: nil).where.not(status: 'indexed')}
  scope :needs_translation_index, -> { where.not(translation_status: nil).where.not(translation_status: 'indexed')}

  module TEXT_TYPE
    TRANSCRIPTION = 'transcription'
    TRANSLATION = 'translation'
  end

  STATUS_TRANSCRIBED = 'transcribed'
  STATUS_INCOMPLETE = 'incomplete'
  STATUS_BLANK = 'blank'
  STATUS_NEEDS_REVIEW = 'review'
  STATUS_INDEXED = 'indexed'
  STATUS_TRANSLATED = 'translated'

  ALL_STATUSES = [
    nil,
    STATUS_INCOMPLETE,
    STATUS_TRANSCRIBED,
    STATUS_NEEDS_REVIEW,
    STATUS_INDEXED,
    STATUS_TRANSLATED,
    STATUS_BLANK
  ]

  MAIN_STATUSES = ALL_STATUSES - [STATUS_TRANSLATED]
  TRANSLATION_STATUSES = ALL_STATUSES - [STATUS_INCOMPLETE, STATUS_TRANSCRIBED]

  # tested
  def collection
    work.collection
  end

  def field_based
    self.collection.field_based
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

  def base_height
    if self[:base_height].blank?
      if self.sc_canvas 
        self.sc_canvas.height
      elsif self.ia_leaf
        self.ia_leaf.page_h
      else
        nil
      end
    else
      self[:base_height]
    end
  end

  def base_width
    if self[:base_width].blank?
      if self.sc_canvas 
        self.sc_canvas.width
      elsif self.ia_leaf
        self.ia_leaf.page_w
      else
        nil
      end
    else
      self[:base_width]
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
    if self.base_image.blank?
      return nil
    end
    if !File.exists?(thumbnail_filename())
      if File.exists?(modernize_absolute(self.base_image))
        generate_thumbnail
      end
    end
    return thumbnail_filename
  end

  def thumbnail_url
    if self.ia_leaf
      self.ia_leaf.thumb_url
    elsif self.sc_canvas
      self.sc_canvas.thumbnail_url
    else
      file_to_url(self.thumbnail_image)
    end
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
    unless User.current_user.nil?
      version.user = User.current_user
    else
      version.user = User.find_by(id: self.work.owner_user_id)
    end
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
      self.sections.delete_all
      self.table_cells.delete_all

      @sections.each do |section|
        section.pages << self
        section.work = self.work
        section.save!
      end

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

  def submit_background_processes(type)
    if type == "transcription"
      latex = self.source_text.scan(LATEX_SNIPPET)
    elsif type == "translation"
      latex = self.source_translation.scan(LATEX_SNIPPET)
    end

    unless latex.blank?
      TexFigure.submit_background_process(self.id)
    end
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

  def verbatim_transcription_plaintext
    formatted_plaintext(self.xml_text)
  end

  def verbatim_translation_plaintext
    formatted_plaintext(self.xml_translation)
  end

  def emended_transcription_plaintext
    emended_plaintext(self.xml_text)
  end

  def emended_translation_plaintext
    emended_plaintext(self.xml_translation)
  end


  def process_spreadsheet(field, cell_data)
    # returns a formatted string
    formatted = String.new
    new_table_cells = []

    # read spreadsheet-wide data like table heading
    formatted << "<table class=\"tabular\"><thead>"

    # read column-specific data like column heading
    column_configs = field.spreadsheet_columns.to_a
    column_configs.each do |column|
      formatted << "<th>#{column.label}</th>"
    end
    checkbox_headers = column_configs.select{|cc| cc.input_type == 'checkbox'}.map{|cc| cc.label }.flatten

    formatted << "</thead><tbody>"
    # write out 
    parsed_cell_data = JSON.parse(cell_data.values.first)
    parsed_cell_data.each_with_index do |row, rownum|
      unless this_and_following_rows_empty?(parsed_cell_data, rownum)
        # row = parsed_cell_data[row_key]
        formatted_row = "<tr>"
        row.each_with_index do |cell, colnum|
          column = column_configs[colnum]
          # save the table cell object
          tc = TableCell.new(row: rownum+1)
          tc.work = self.work
          tc.page = self
          tc.transcription_field_id = field.id
          tc.header = column.label
          if cell.blank?
            cell = ''
          elsif cell.to_s.scan('<').count != cell.to_s.scan('>').count # broken tags or actual < / > signs
            cell = ERB::Util.html_escape(cell)
          end
          if checkbox_headers.include? tc.header
            tc.content = (cell == 'true').to_s
          else
            tc.content = cell
          end
          new_table_cells << tc

          # format the cell
          formatted_row << "<td>#{cell}</td>"
        end
        formatted_row << "</tr>"
        formatted << formatted_row
      end
    end
    formatted << "</tbody></table>"

    [formatted, new_table_cells]
  end

  def this_and_following_rows_empty?(cell_data, rownum)
    remaining_rows = cell_data[rownum..(cell_data.count - 1)]

    row_with_value = remaining_rows.detect { |row|  row.detect{|cell| !cell.blank? } }

    row_with_value.nil?
  end

  def replace_table_cells(new_table_cells)
    self.table_cells.insert_all(new_table_cells.map{|obj| obj.attributes.merge({created_at: Time.now, updated_at: Time.now})})
  end

  #create table cells if the collection is field based
  def process_fields(field_cells)
    new_table_cells = []
    string = String.new
    unless field_cells.blank?
      field_cells.each do |id, cell_data|
        field = TranscriptionField.find(id.to_i)
        input_type = field.input_type
        if input_type == 'spreadsheet'
          spreadsheet_string, spreadsheet_cells = process_spreadsheet(field, cell_data)
          string << spreadsheet_string
          new_table_cells += spreadsheet_cells
        else
          tc = TableCell.new(row: 1)
          tc.work = self.work
          tc.page = self
          tc.transcription_field_id = id.to_i

          cell_data.each do |key, value|
            if value.scan('<').count != value.scan('>').count # broken tags or actual < / > signs
              value = ERB::Util.html_escape(value)
            end
            tc.header = key
            tc.content = value
            key = (input_type == "description") ? (key + " ") : (key + ": ")
            string << "<span class=\"field__label\">" + key + "</span>" + value + "\n\n"
          end

          new_table_cells << tc
        end
      end
    end
    self.source_text = string
    new_table_cells
  end

  #######################
  # XML Source support
  #######################

  def clear_links(text_type)
    # first use the existing links to blank the graphs
    if self.page_article_links.present?
      self.clear_article_graphs
      # clear out the existing links to this page
      PageArticleLink.where("page_id = #{self.id} and text_type = '#{text_type}'").delete_all
    end
  end

  # tested
  def create_link(article, display_text, text_type)
    link = PageArticleLink.new(page: self, article: article,
                               display_text: display_text, text_type: text_type)
    link.save!
    return link.id
  end

  def thumbnail_filename
    filename=modernize_absolute(self.base_image)
    ext=File.extname(filename)
    filename.sub(/#{ext}$/,"_thumb#{ext}")
  end

  def remove_transcription_links(text)
    self.update_columns(source_text: remove_square_braces(text))
    @text_dirty = true
    process_source
    self.status = 'transcribed'
    self.save!
  end

  def remove_translation_links(text)
    self.update_columns(source_translation: remove_square_braces(text))
    @translation_dirty = true
    process_source
    self.status = 'translated'
    self.save!
  end

  def validate_blank_page
    unless self.status == Page::STATUS_BLANK
      self.status = nil if self.source_text.blank?
    end
  end

  def update_work_stats
    if self.work
      self.work.work_statistic.recalculate
    end
  end

  def contributors
    users = []

    page = self

    page.page_versions.each do |page|
      user = { name: page.user.display_name }
      user[:orcid] = page.user.orcid unless page.user.orcid.blank?
      users << user unless users.include?(user)
    end

    users
  end

  private

  def emended_plaintext(source)
    doc = Nokogiri::XML(source)
    doc.xpath("//link").each { |n| n.replace(n['target_title'])}
    doc.xpath("//abbr").each { |n| n.replace(n['expan'])}
    formatted_plaintext_doc(doc)
  end

  def formatted_plaintext(source)
    doc = Nokogiri::XML(source)
    doc.xpath("//expan").each { |n| n.replace(n['orig'])}
    doc.xpath("//reg").each { |n| n.replace(n['orig'])}
    formatted_plaintext_doc(doc)
  end

  def formatted_plaintext_doc(doc)
    doc.xpath("//p").each { |n| n.add_next_sibling("\n\n")}
    doc.xpath("//lb[@break='no']").each do |n| 
      if n.text.blank?
        sigil = '-'
      else
        sigil = n.text
      end
      n.replace("#{sigil}\n")
    end
    doc.xpath("//table").each { |n| formatted_plaintext_table(n) }
    doc.xpath("//lb").each { |n| n.replace("\n")}
    doc.xpath("//br").each { |n| n.replace("\n")}
    doc.xpath("//div").each { |n| n.add_next_sibling("\n")}
    doc.xpath("//footnote").each { |n| n.replace('')}

    doc.text.sub(/^\s*/m, '').gsub(/ *$/m,'')
  end

  def formatted_plaintext_table(table_element)
    text_table = ""

    # clean up in-cell line-breaks
    table_element.xpath('//lb').each { |n| n.replace(' ')}

    # calculate the widths of each column based on max(header, cell[0...end])
    column_count = ([table_element.xpath("//th").count] + table_element.xpath('//tr').map{|e| e.xpath('td').count }).max
    column_widths = {}
    1.upto(column_count) do |column_index|
      longest_cell = (table_element.xpath("//tr/td[position()=#{column_index}]").map{|e| e.text().length}.max || 0)
      corresponding_heading = heading_length = table_element.xpath("//th[position()=#{column_index}]").first
      heading_length = corresponding_heading.nil? ? 0 : corresponding_heading.text().length
      column_widths[column_index] = [longest_cell, heading_length].max
    end

    # print the header as markdown
    cell_strings = []
    table_element.xpath("//th").each_with_index do |e,i|
      cell_strings << e.text.rjust(column_widths[i+1], ' ')
    end
    text_table << cell_strings.join(' | ') << "\n"

    # print the separator
    text_table << column_count.times.map{|i| ''.rjust(column_widths[i+1], '-')}.join(' | ') << "\n"

    # print each row as markdown
    table_element.xpath('//tr').each do |row_element|
      text_table << row_element.xpath('td').map{|e| e.text.rjust(column_widths[e.path.match(/.*\[(\d+)\]/)[1].to_i], ' ') }.join(' | ') << "\n"
    end

    table_element.replace(text_table)
  end


  def modernize_absolute(filename)
    if filename
      File.join(Rails.root, 'public', filename.sub(/.*public/, ''))
    else
      ""
    end
  end

  def generate_thumbnail
    image = Magick::ImageList.new(modernize_absolute(self[:base_image]))
    factor = 400.to_f / self[:base_height].to_f
    image.thumbnail!(factor)
    image.write(thumbnail_filename)
    image = nil
  end

  def delete_deeds
    Deed.where(page_id: self.id).destroy_all
  end

  def update_featured_page
    self.work.update_columns(featured_page: nil)
  end

end
