# == Schema Information
#
# Table name: pages
#
#  id                      :integer          not null, primary key
#  approval_delta          :float(24)
#  base_height             :integer
#  base_image              :string(255)
#  base_width              :integer
#  created_on              :datetime
#  edit_started_at         :datetime
#  last_note_updated_at    :datetime
#  line_count              :integer
#  lock_version            :integer          default(0)
#  metadata                :text(65535)
#  position                :integer
#  search_text             :text(65535)
#  shrink_factor           :integer
#  source_text             :text(16777215)
#  source_translation      :text(16777215)
#  status                  :string(255)
#  title                   :string(255)
#  translation_status      :string(255)
#  xml_text                :text(16777215)
#  xml_translation         :text(16777215)
#  updated_at              :datetime
#  edit_started_by_user_id :integer
#  last_editor_user_id     :integer
#  page_version_id         :integer
#  work_id                 :integer
#
# Indexes
#
#  index_pages_on_edit_started_by_user_id                 (edit_started_by_user_id)
#  index_pages_on_status_and_work_id_and_edit_started_at  (status,work_id,edit_started_at)
#  index_pages_on_work_id                                 (work_id)
#  pages_search_text_index                                (search_text)
#
require 'search_translator'
require 'transkribus/page_processor'
class Page < ApplicationRecord

  ActiveRecord::Base.lock_optimistically = false

  include XmlSourceProcessor
  include ApplicationHelper

  after_initialize :defaults
  before_save :calculate_last_editor
  before_save :calculate_approval_delta
  before_update :validate_blank_page
  before_update :process_source
  before_update :populate_search
  before_update :update_line_count
  validate :validate_source, :validate_source_translation

  belongs_to :work, optional: true
  acts_as_list scope: :work
  belongs_to :last_editor, class_name: 'User', foreign_key: 'last_editor_user_id', optional: true

  has_many :page_article_links, dependent: :destroy
  has_many :articles, through: :page_article_links
  has_many :page_versions, -> { order 'page_version DESC' }, dependent: :destroy

  belongs_to :current_version, class_name: 'PageVersion', foreign_key: 'page_version_id', optional: true

  has_and_belongs_to_many :sections

  has_many :notes, -> { order 'created_at' }, dependent: :destroy
  has_one :ia_leaf, dependent: :destroy
  has_one :sc_canvas, dependent: :destroy
  has_many :table_cells, dependent: :destroy
  has_many :tex_figures, dependent: :destroy
  has_many :deeds, dependent: :destroy
  has_many :external_api_requests, dependent: :destroy

  after_destroy :update_work_stats
  # after_destroy :delete_deeds
  after_destroy :update_featured_page, if: proc { |page| page.work.featured_page == page.id }
  after_save :create_version
  after_save :update_sections_and_tables
  after_save :update_tex_figures
  after_save do
    work.update_next_untranscribed_pages if (self == work.next_untranscribed_page) || work.next_untranscribed_page.nil?
    work.work_statistic.update_last_edit_date if saved_change_to_source_text? || saved_change_to_source_translation?
  end

  serialize :metadata, type: Hash

  scope :review, -> { where(status: 'review') }
  scope :incomplete, -> { where(status: 'incomplete') }
  scope :translation_review, -> { where(translation_status: 'review') }
  scope :needs_transcription, -> { where(status: [nil]) }
  scope :needs_completion, -> { where(status: [STATUS_INCOMPLETE]) }
  scope :needs_translation, -> { where(translation_status: nil) }
  scope :needs_index, -> { where.not(status: nil).where.not(status: 'indexed') }
  scope :needs_translation_index, -> { where.not(translation_status: nil).where.not(translation_status: 'indexed') }

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
  COMPLETED_STATUSES = [STATUS_TRANSCRIBED, STATUS_TRANSLATED, STATUS_INDEXED, STATUS_BLANK]
  NOT_INCOMPLETE_STATUSES = COMPLETED_STATUSES + [STATUS_NEEDS_REVIEW]

  NEEDS_WORK_STATUSES = [
    nil,
    STATUS_INCOMPLETE
  ]

  # tested
  delegate :collection, to: :work

  delegate :field_based, to: :collection

  def articles_with_text
    articles conditions: ['articles.source_text is not null']
  end

  def defaults
    return if self[:title].present?

    self[:title] = "Untitled Page #{self[:position]}"
  end

  # we need a short pagename for index entries
  # in this case this will refer to an entry without
  # superfluous information that would be redundant
  # within the context of a chapter
  # TODO: convert to use a regex stored on the work
  def title_for_print_index
    if title.match(/\w+\W+\w+\W+(\w+)/)
      ::Regexp.last_match(1)
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
    if ia_leaf
      ia_leaf.facsimile_url
    elsif sc_canvas
      sc_canvas.facsimile_url
    else
      base_image
    end
  end

  def base_height
    if self[:base_height].blank?
      if sc_canvas
        sc_canvas.height
      elsif ia_leaf
        ia_leaf.page_h
      end
    else
      self[:base_height]
    end
  end

  def base_width
    if self[:base_width].blank?
      if sc_canvas
        sc_canvas.width
      elsif ia_leaf
        ia_leaf.page_w
      end
    else
      self[:base_width]
    end
  end

  def base_image
    self[:base_image] || ''
  end

  def shrink_factor
    self[:shrink_factor] || 0
  end

  def scaled_image(factor = 2)
    if factor == 0
      base_image
    else
      base_image.sub(/.jpg/, "_#{factor}.jpg")
    end
  end

  # Returns the thumbnail filename
  # creates the image if it's not present
  def thumbnail_image
    return nil if ia_leaf
    return nil if base_image.blank?

    generate_thumbnail if !File.exist?(thumbnail_filename) && File.exist?(modernize_absolute(base_image))
    thumbnail_filename
  end

  def thumbnail_url
    if ia_leaf
      ia_leaf.thumb_url
    elsif sc_canvas
      sc_canvas.thumbnail_url
    else
      file_to_url(thumbnail_image)
    end
  end

  def calculate_last_editor
    return if COMPLETED_STATUSES.include? status

    self.last_editor = User.current_user
  end

  def calculate_approval_delta
    return unless source_text_changed?

    if COMPLETED_STATUSES.include? status
      most_recent_not_approver_version = page_versions.where.not(user_id: User.current_user&.id).first
      if most_recent_not_approver_version
        old_transcription = most_recent_not_approver_version.transcription || ''
      else
        old_transcription = ''
      end
      new_transcription = source_text

      if new_transcription.blank? && old_transcription.blank?
        self.approval_delta = nil
      else
        self.approval_delta =
          Text::Levenshtein.distance(old_transcription, new_transcription).fdiv((old_transcription.size + new_transcription.size))
      end
    else # zero out deltas if the page is not complete
      self.approval_delta = nil
    end
  end

  def create_version
    return unless saved_change_to_source_text? || saved_change_to_title? || saved_changes.present?

    version = PageVersion.new
    version.page = self
    version.title = title
    version.transcription = source_text
    version.xml_transcription = xml_text
    version.source_translation = source_translation
    version.xml_translation = xml_translation
    version.status = status

    # Add other attributes as needed

    if User.current_user.nil?
      version.user = User.find_by(id: work.owner_user_id)
    else
      version.user = User.current_user
    end

    # now do the complicated version update thing
    version.work_version = work.transcription_version
    work.increment!(:transcription_version)

    previous_version = PageVersion.where(page_id: id).order('page_version DESC').first
    version.page_version = previous_version.page_version + 1 if previous_version
    version.save!

    update_column(:page_version_id, version.id) # set current_version
  end

  def update_sections_and_tables
    return unless @sections

    sections.delete_all
    table_cells.delete_all

    @sections.each do |section|
      section.pages << self
      section.work = work
      section.save!
    end

    @tables.each do |table|
      table[:rows].each_with_index do |row, rownum|
        row.each_with_index do |cell, cell_index|
          tc = TableCell.new(row: rownum,
            content: cell,
            header: table[:header][cell_index])
          tc.work = work
          tc.page = self
          tc.section = table[:section]
          tc.save!
        end
      end
    end
  end

  def submit_background_processes(type)
    if type == 'transcription'
      latex = source_text.scan(LATEX_SNIPPET)
    elsif type == 'translation'
      latex = source_translation.scan(LATEX_SNIPPET)
    end

    return if latex.blank?

    TexFigure.submit_background_process(id)
  end

  def update_tex_figures
    tex_figures.each do |tex_figure|
      tex_figure.save! if tex_figure.changed?
    end
  end

  def update_line_count
    self.line_count = calculate_line_count
  end

  def calculate_line_count
    if work && collection
      if field_based
        # count table rows
        table_cells.pluck(:row).uniq.count
      elsif source_text.nil?
        # count non-blank lines in the source
        0
      else
        source_text.lines.select { |line| line.match(/\S/) }.count
      end
    else
      # intermediary format -- collection is probably being imported
      0
    end
  end

  # This deletes all graphs within associated articles
  # It should be called twice whenever a page is changed
  # once to reset the previous links, once to reset new links
  def clear_article_graphs
    article_ids = page_article_links.pluck(:article_id)
    Article.where(id: article_ids).update_all(graph_image: nil)
  end

  def populate_search
    self.search_text = SearchTranslator.search_text_from_xml(xml_text, xml_translation)
  end

  def verbatim_transcription_plaintext
    formatted_plaintext(xml_text)
  end

  def verbatim_translation_plaintext
    formatted_plaintext(xml_translation)
  end

  def emended_transcription_plaintext
    emended_plaintext(xml_text)
  end

  def emended_translation_plaintext
    emended_plaintext(xml_translation)
  end

  def process_spreadsheet(field, cell_data)
    # returns a formatted string
    formatted = String.new
    new_table_cells = []

    # read spreadsheet-wide data like table heading
    formatted << '<table class="tabular"><thead>'

    # read column-specific data like column heading
    column_configs = field.spreadsheet_columns.to_a
    column_configs.each do |column|
      formatted << "<th>#{column.label}</th>"
    end
    checkbox_headers = column_configs.select { |cc| cc.input_type == 'checkbox' }.map(&:label).flatten

    formatted << '</thead><tbody>'
    # write out
    parsed_cell_data = JSON.parse(cell_data.values.first)
    parsed_cell_data.each_with_index do |row, rownum|
      next if this_and_following_rows_empty?(parsed_cell_data, rownum)

      # row = parsed_cell_data[row_key]
      formatted_row = '<tr>'
      row.each_with_index do |cell, colnum|
        column = column_configs[colnum]
        # save the table cell object
        tc = TableCell.new(row: rownum + 1)
        tc.work = work
        tc.page = self
        tc.transcription_field_id = field.id
        tc.header = column.label
        if cell.blank?
          cell = ''
        elsif cell.to_s.scan('<').count != cell.to_s.scan('>').count # broken tags or actual < / > signs
          cell = ERB::Util.html_escape(cell)
        end
        if checkbox_headers.include? tc.header
          tc.content = ['true', true].include?(cell).to_s
        else
          tc.content = cell
        end
        new_table_cells << tc

        # format the cell
        formatted_row << "<td>#{cell}</td>"
      end
      formatted_row << '</tr>'
      formatted << formatted_row
    end
    formatted << '</tbody></table>'

    [formatted, new_table_cells]
  end

  def this_and_following_rows_empty?(cell_data, rownum)
    remaining_rows = cell_data[rownum..(cell_data.count - 1)]

    row_with_value = remaining_rows.detect { |row| row.detect(&:present?) }

    row_with_value.nil?
  end

  def replace_table_cells(new_table_cells)
    table_cells.insert_all(new_table_cells.map { |obj| obj.attributes.merge({ created_at: Time.now, updated_at: Time.now }) })
  end

  # create table cells if the collection is field based
  def process_fields(field_cells)
    new_table_cells = []
    string = String.new
    if field_cells.present?
      field_cells.each do |id, cell_data|
        field = TranscriptionField.find(id.to_i)
        input_type = field.input_type
        if input_type == 'spreadsheet'
          spreadsheet_string, spreadsheet_cells = process_spreadsheet(field, cell_data)
          string << spreadsheet_string
          new_table_cells += spreadsheet_cells
        else
          tc = TableCell.new(row: 1)
          tc.work = work
          tc.page = self
          tc.transcription_field_id = id.to_i

          cell_data.each do |key, value|
            value = ERB::Util.html_escape(value) if value.scan('<').count != value.scan('>').count # broken tags or actual < / > signs
            tc.header = key
            tc.content = value
            key = input_type == 'description' ? "#{key} " : "#{key}: "
            string << ("<span class=\"field__label\">#{key}</span>#{value}\n\n")
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
    return if page_article_links.blank?

    clear_article_graphs
    # clear out the existing links to this page
    PageArticleLink.where("page_id = #{id} and text_type = '#{text_type}'").delete_all
  end

  # tested
  def create_link(article, display_text, text_type)
    link = PageArticleLink.new(page: self, article:,
      display_text:, text_type:)
    link.save!
    link.id
  end

  def thumbnail_filename
    filename = modernize_absolute(base_image)
    ext = File.extname(filename)
    filename.sub(/#{ext}$/, "_thumb#{ext}")
  end

  def remove_transcription_links(text)
    update_columns(source_text: remove_square_braces(text))
    @text_dirty = true
    process_source
    self.status = 'transcribed'
    save!
  end

  def remove_translation_links(text)
    update_columns(source_translation: remove_square_braces(text))
    @translation_dirty = true
    process_source
    self.status = 'translated'
    save!
  end

  def validate_blank_page
    return if status == Page::STATUS_BLANK

    self.status = nil if source_text.blank?
  end

  def update_work_stats
    return unless work

    work.work_statistic.recalculate
  end

  def contributors
    users = []

    page = self

    page.page_versions.each do |page|
      user = { name: page.user.display_name }
      user[:orcid] = page.user.orcid if page.user.orcid.present?
      users << user unless users.include?(user)
    end

    users
  end

  def has_ai_plaintext?
    File.exist?(ai_plaintext_path)
  end

  def ai_plaintext
    if has_ai_plaintext?
      File.read(ai_plaintext_path)
    else
      ''
    end
  end

  def ai_plaintext=(text)
    FileUtils.mkdir_p(File.dirname(ai_plaintext_path))
    File.write(ai_plaintext_path, text)
  end

  def has_alto?
    File.exist?(alto_path)
  end

  def alto_xml
    if has_alto?
      File.read(alto_path)
    else
      ''
    end
  end

  def alto_xml=(xml)
    FileUtils.mkdir_p(File.dirname(alto_path))
    File.write(alto_path, xml)
  end

  def image_url_for_download
    if sc_canvas
      sc_canvas.sc_resource_id
    elsif ia_leaf
      ia_leaf.facsimile_url
    else
      uri = URI.parse(file_to_url(canonical_facsimile_url).gsub(' ', '+'))
      # if we are in test, we will be http://localhost:3000 and need to separate out the port from the host
      raw_host = Rails.application.config.action_mailer.default_url_options[:host]
      host = raw_host.split(':')[0]
      uri.host = host
      port = raw_host.split(':')[1]
      if port
        uri.scheme = 'http'
        uri.port = port
      else
        uri.scheme = 'https'
      end
      uri.to_s
    end
  end

  private

  def ai_plaintext_path
    Rails.public_path.join('text', work_id.to_s, "#{id}_ai_plaintext.txt")
  end

  def alto_path
    Rails.public_path.join('text', work_id.to_s, "#{id}_alto.xml")
  end

  def original_htr_path
    '/not/implemented/yet/placeholder.xml'
  end

  def emended_plaintext(source)
    doc = Nokogiri::XML(source)
    doc.xpath('//link').each { |n| n.replace(n['target_title']) }
    doc.xpath('//abbr').each { |n| n.replace(n['expan']) }
    formatted_plaintext_doc(doc)
  end

  def formatted_plaintext(source)
    doc = Nokogiri::XML(source)
    doc.xpath('//expan').each do |n|
      replacement = n['abbr'] || n['orig'] || n.text
      n.replace(replacement)
    end
    doc.xpath('//reg').each do |n|
      replacement = n['orig'] || n.text
      n.replace(replacement)
    end
    formatted_plaintext_doc(doc)
  end

  def formatted_plaintext_doc(doc)
    doc.xpath('//p').each { |n| n.add_next_sibling("\n\n") }
    doc.xpath("//lb[@break='no']").each do |n|
      if n.text.blank?
        sigil = '-'
      else
        sigil = n.text
      end
      n.replace("#{sigil}\n")
    end
    doc.xpath('//table').each { |n| formatted_plaintext_table(n) }
    doc.xpath('//lb').each { |n| n.replace("\n") }
    doc.xpath('//br').each { |n| n.replace("\n") }
    doc.xpath('//div').each { |n| n.add_next_sibling("\n") }
    doc.xpath('//footnote').each { |n| n.replace('') }

    doc.text.sub(/^\s*/m, '').gsub(/ *$/m, '')
  end

  def formatted_plaintext_table(table_element)
    text_table = xml_table_to_markdown_table(table_element)
    table_element.replace(text_table)
  end

  def modernize_absolute(filename)
    if filename
      File.join(Rails.root.to_s, 'public', filename.sub(/.*public/, ''))
    else
      ''
    end
  end

  def generate_thumbnail
    image = Magick::ImageList.new(modernize_absolute(self[:base_image]))
    factor = 400.fdiv(self[:base_height])
    image.thumbnail!(factor)
    image.write(thumbnail_filename)
    nil
  end

  def delete_deeds
    Deed.where(page_id: id).destroy_all
  end

  def update_featured_page
    work.update_columns(featured_page: nil)
  end

end
