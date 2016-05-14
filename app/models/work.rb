class Work < ActiveRecord::Base
  has_many :pages, -> { order 'position' }
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  belongs_to :collection
  has_many :deeds, -> { order 'created_at DESC' }
  has_one :ia_work
  has_one :omeka_item
  has_one :sc_manifest
  has_one :work_statistic
  has_many :sections, -> { order 'position' }
  has_many :table_cells, -> { order 'page_id, row, header' }

  has_and_belongs_to_many :scribes, :class_name => 'User', :join_table => :transcribe_authorizations
  has_and_belongs_to_many :document_sets

  after_save :update_statistic

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
                  :pages_are_meaningful

  validates :title, presence: true, length: { minimum: 3 }


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

  def articles
    my_articles = []
    for page in self.pages
      for article in page.articles
        my_articles << article
      end
    end
    my_articles.uniq!
    logger.debug("DEBUG: articles=#{my_articles}")
    return my_articles
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
    unless self.work_statistic
      self.work_statistic = WorkStatistic.new
    end
    self.work_statistic.recalculate
  end

  def cell_to_xml(cell)
    REXML::Document.new('<?xml version="1.0" encoding="UTF-8"?><cell>' + cell.content.gsub('&','&amp;') + '</cell>')
  end

  def cell_to_plaintext(cell)
#    binding.pry if cell.content =~ /Brimstone/
    doc = cell_to_xml(cell)
    doc.each_element('.//text()') { |e| p e.text }.join
  end

  def cell_to_subject(cell)
    doc = cell_to_xml(cell)
    subjects = ""
    doc.elements.each("//link") do |e|
      title = e.attributes['target_title']
      subjects << title
      subjects << "\n"
    end
    subjects
  end

  def export_tables_as_csv
    raw_headings = self.table_cells.pluck('DISTINCT header')
    headings = []
    raw_headings.each do |raw_heading|
      munged_heading = raw_heading  #.sub(/^\s*!?/,'').sub(/\s*$/,'')
      headings << "#{munged_heading} (text)"
      headings << "#{munged_heading} (subject)"
    end
    
    csv_string = CSV.generate(:force_quotes => true) do |csv|
      csv << (%w{ Page_Title Page_Position Page_URL Section } + headings)
      self.pages.each do |page|
        unless page.table_cells.empty?
          page_url="http://localhost:3000/display/display_page?page_id=#{page.id}"
          page_cells = [page.title, page.position, page_url]
          data_cells = Array.new(headings.count + 1, "")
          section_title = nil
          section = nil
          row = nil
          page.table_cells.each do |cell|
            if section != cell.section
              section_title = cell.section.title
            end 
            if row != cell.row
              if row
                # write the record to the CSV and start a new record
                csv << (page_cells + data_cells)
              end
              data_cells = Array.new(headings.count + 1, "")            
              data_cells[0] = section_title
              row = cell.row
            end
            
            target = raw_headings.index(cell.header) + 1
            data_cells[target*2-1] = cell_to_plaintext(cell)
            data_cells[target*2] = cell_to_subject(cell)
          end
        end
      end
    end
    csv_string
  end
end