module ExportService
  include AbstractXmlHelper

  def add_readme_to_zip(dirname:, out:)
    readme = "#{Rails.root}/doc/zip/README"
    file = File.open(readme, "r")
    path = File.join dirname, 'README.txt'
    out.put_next_entry path
    out.write file.read
  end

  def export_work_metadata_csv(dirname:, out:, collection:)
    path = "work_metadata.csv"
    out.put_next_entry(path)
    out.write(export_work_metadata_as_csv(collection))
  end

  def export_subject_csv(dirname:, out:, collection:)
    path = "subject_index.csv"
    out.put_next_entry(path)
    out.write(collection.export_subject_index_as_csv)
  end

  def export_table_csv_collection(dirname:, out:, collection:)
    path = "fields_and_tables.csv"
    out.put_next_entry(path)
    out.write(export_tables_as_csv(collection))
  end

  def export_table_csv_work(dirname:, out:, work:)
    path = "fields_and_tables.csv"
    out.put_next_entry(path)
    out.write(export_tables_as_csv(work))
    # path = "subject_index.csv"
    # out.put_next_entry(path)
    # out.write(collection.export_subjects_as_csv)
  end

  def export_tei(dirname:, out:, export_user:)
    path = File.join dirname, 'tei', "tei.xml"
    out.put_next_entry path
    out.write work_to_tei(@work, export_user)
  end

  def export_plaintext_transcript(name:, dirname:, out:)
    path = File.join dirname, 'plaintext', "#{name}_transcript.txt"

    case name
    when "verbatim"
      out.put_next_entry path
      out.write @work.verbatim_transcription_plaintext
    when "expanded"
      if @work.collection.subjects_disabled
        out.put_next_entry path
        out.write @work.emended_transcription_plaintext
      end
    when "searchable"
      out.put_next_entry path
      out.write @work.searchable_plaintext
    end
  end

  def export_plaintext_translation(name:, dirname:, out:)
    path = File.join dirname, 'plaintext', "#{name}_translation.txt"

    if @work.supports_translation?
      case name
      when "verbatim"
        out.put_next_entry path
        out.write @work.verbatim_translation_plaintext
      when "expanded"
        if @work.collection.subjects_disabled
          out.put_next_entry path
          out.write @work.emended_translation_plaintext
        end
      end
    end
  end

  def export_plaintext_transcript_pages(name:, dirname:, out:, page:)
    path = File.join dirname, 'plaintext', "#{name}_transcript_pages", "#{page.title}.txt"

    case name
    when "verbatim"
      out.put_next_entry path
      out.write page.verbatim_transcription_plaintext
    when "expanded"
      if page.collection.subjects_disabled
        out.put_next_entry path
        out.write page.emended_transcription_plaintext
      end
    end
  end

  def export_plaintext_translation_pages(name:, dirname:, out:, page:)
    path = File.join dirname, 'plaintext', "#{name}_translation_pages", "#{page.title}.txt"

    if @work.supports_translation?
      case name
      when "verbatim"
        out.put_next_entry path
        out.write page.verbatim_translation_plaintext
      when "expanded"
        if page.collection.subjects_disabled
          out.put_next_entry path
          out.write page.emended_translation_plaintext
        end
      end
    end
  end

  def export_view(name:, dirname:, out:, export_user:)
    path = File.join dirname, 'html', "#{name}.html"

    case name
    when "full"
      full_view = ApplicationController.new.render_to_string(
        :template => 'export/show', 
        :formats => [:html], 
        :work_id => @work.id, 
        :layout => false, 
        :encoding => 'utf-8',
        :assigns => {
          :collection => @work.collection,
          :work => @work,
          :export_user => export_user
        })
      out.put_next_entry path
      out.write full_view
    when "text"
      text_view = ApplicationController.new.render_to_string(
        :template => 'export/text', 
        :formats => [:html], 
        :work_id => @work.id, 
        :layout => false, 
        :encoding => 'utf-8',
        :assigns => {
          :collection => @work.collection,
          :work => @work,
          :export_user => export_user
        })
      out.put_next_entry path
      out.write text_view
    when "transcript"
      transcript_view = ApplicationController.new.render_to_string(
        :template => 'export/transcript', 
        :formats => [:html], 
        :work_id => @work.id, 
        :layout => false, 
        :encoding => 'utf-8',
        :assigns => {
          :collection => @work.collection,
          :work => @work,
          :export_user => export_user
        })
      out.put_next_entry path
      out.write transcript_view
    when "translation"
      if @work.supports_translation?
        translation_view = ApplicationController.new.render_to_string(
          :template => 'export/translation', 
          :formats => [:html], 
          :work_id => @work.id, 
          :layout => false, 
          :encoding => 'utf-8',
          :assigns => {
            :collection => @work.collection,
            :work => @work,
            :export_user => export_user
          })
        out.put_next_entry path
        out.write translation_view
      end
    end
  end

  def export_html_full_pages(dirname:, out:, page:)
    path = File.join dirname, 'html', 'full_pages', "#{page.title}.html"

    out.put_next_entry path

    page_view = xml_to_html(page.xml_text, true, false, page.work.collection)
    out.write page_view
  end

private

  def spreadsheet_heading_to_indexable(field_id, column_label)
    {field_id => column_label}
  end

  def spreadsheet_column_to_indexable(column)
    spreadsheet_heading_to_indexable(column.transcription_field_id, column.label)
  end

  def get_headings(collection, ids)
    field_headings = collection.transcription_fields.order(:line_number, :position).where.not(input_type: 'instruction').pluck(:id)
    orphan_cell_headings = TableCell.where(work_id: ids).where("transcription_field_id not in (select id from transcription_fields)").pluck(Arel.sql('DISTINCT header'))
    markdown_cell_headings = TableCell.where(work_id: ids).where("transcription_field_id is null").pluck(Arel.sql('DISTINCT header'))
    cell_headings = orphan_cell_headings + markdown_cell_headings

    @raw_headings = (field_headings + cell_headings).uniq
    @headings = []

    @page_metadata_headings = collection.page_metadata_fields
    @headings += @page_metadata_headings

    #get headings from field-based
    field_headings.each do |field_id|
      field = TranscriptionField.where(:id => field_id).first
      if field && field.input_type == 'spreadsheet'
        raw_field_index = @raw_headings.index(field_id)
        field.spreadsheet_columns.each do |column|
          raw_field_index += 1
          raw_heading = "#{field.label} #{column.label}"
          @raw_headings.insert(raw_field_index, spreadsheet_column_to_indexable(column))
          @headings << "#{raw_heading} (text)"
          @headings << "#{raw_heading} (subject)"
        end
        @raw_headings.delete(field_id)
      else
        raw_heading = field ? field.label : field_id
        @headings << "#{raw_heading} (text)"
        @headings << "#{raw_heading} (subject)"
      end
    end
    #get headings from non-field-based
    cell_headings.each do |raw_heading|
      @headings << "#{raw_heading} (text)"
      @headings << "#{raw_heading} (subject)"
    end
    @headings
  end


  def export_work_metadata_as_csv(collection)
    csv_string = CSV.generate(:force_quotes => true) do |csv|
      static_headers = [
        'Title', 
        'Collection', 
        'Document Sets', 
        'Uploaded Filename', 
        'FromThePage ID',
        'FromThePage Slug',
        'FromThePage URL',
        'Identifier',
        'Originating Manifest ID',
        'Total Pages',
        'Pages Transcribed',
        'Pages Corrected',
        'Pages Indexed',
        'Pages Translated',
        'Pages Needing Review',
        'Pages Marked Blank'
      ]

      metadata_headers = [
      ]

      csv << static_headers + metadata_headers

      collection.works.includes(:document_sets, :work_statistic).reorder(:id).each do |work| 
        row = [
          work.title,
          work.collection.title,
          work.document_sets.map{|ds| ds.title}. join('|'),
          work.uploaded_filename,
          work.id,
          work.slug,
          collection_read_work_url(collection.owner, collection, work),
          work.identifier,
          work.sc_manifest.nil? ? '' : work.sc_manifest.at_id,
          work.work_statistic.total_pages,
          work.work_statistic.transcribed_pages,
          work.work_statistic.corrected_pages,
          work.work_statistic.annotated_pages,
          work.work_statistic.translated_pages,
          work.work_statistic.needs_review,
          work.work_statistic.blank_pages
        ]

        csv << row
      end
    end

    csv_string
  end

  def export_tables_as_csv(table_obj)
    if table_obj.is_a?(Collection)
      collection = table_obj
      ids = table_obj.works.ids
      works = table_obj.works
    elsif table_obj.is_a?(Work)
      collection = table_obj.collection
      #need arrays so they will act equivalently to the collection works
      ids = [table_obj.id]
      works = [table_obj]
    end

    get_headings(collection, ids)

    csv_string = CSV.generate(:force_quotes => true) do |csv|

      page_cells = [
        'Work Title',
        'Work Identifier',
        'Page Title',
        'Page Position',
        'Page URL',
        'Page Contributors',
        'Page Notes'
      ]

      section_cells = [
        'Section (text)',
        'Section (subjects)',
        'Section (subject categories)'
      ]

      if table_obj.sections.blank?
        csv << (page_cells + @headings)
        col_sections = false
      else
        csv << (page_cells + section_cells + @headings)
        col_sections = true
      end

      works.each do |w|
        csv = generate_csv(w, csv, col_sections)
      end

    end
    csv_string
  end

  def generate_csv(work, csv, col_sections)
    all_deeds = work.deeds
    work.pages.includes(:table_cells).each do |page|
      unless page.table_cells.empty?
        page_url=url_for({:controller=>'display',:action => 'display_page', :page_id => page.id, :only_path => false})
        page_notes = page.notes
          .map{ |n| "[#{n.user.display_name}<#{n.user.email}>]: #{n.body}" }.join('|').gsub('|', '//').gsub(/\s+/, ' ')
        page_contributors = all_deeds
          .select{ |d| d.page_id == page.id}
          .map{ |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }
          .uniq.join('|')

        page_cells = [
          work.title,
          work.identifier,
          page.title,
          page.position,
          page_url,
          page_contributors,
          page_notes
        ]

        page_metadata_cells = page_metadata_cells(page)
        data_cells = Array.new(@headings.count, "")

        if page.sections.blank?
          #get cell data for a page with only one table
          page.table_cells.group_by(&:row).each do |row, cell_array|
            #get the cell data and add it to the array
            cell_data(cell_array, @raw_headings, data_cells)
            #shift cells over if any page has sections
            if !col_sections
              section_cells = []
            else
              section_cells = ["", "", ""]
            end
            # write the record to the CSV and start a new record
            csv << (page_cells + page_metadata_cells + section_cells + data_cells)
            #create a new array for the next row
            data_cells = Array.new(@headings.count, "")
          end

        else
          #get the table sections/headers and iterate cells within the sections
          page.sections.each do |section|
            section_title_text = XmlSourceProcessor::cell_to_plaintext(section.title) || nil
            section_title_subjects = XmlSourceProcessor::cell_to_subject(section.title) || nil
            section_title_categories = XmlSourceProcessor::cell_to_category(section.title) || nil
            section_cells = [section_title_text, section_title_subjects, section_title_categories]
            #group the table cells per section into rows
            section.table_cells.group_by(&:row).each do |row, cell_array|
              #get the cell data and add it to the array
              cell_data(cell_array, @raw_headings, data_cells)
              # write the record to the CSV and start a new record
              csv << (page_cells + page_metadata_cells + section_cells + data_cells)
              #create a new array for the next row
              data_cells = Array.new(@headings.count, "")
            end
          end
        end
      end
    end
    return csv
  end

  def page_metadata_cells(page)
    metadata_cells = []
    @page_metadata_headings.each do |key|
      metadata_cells << page.metadata[key]
    end

    metadata_cells
  end


  def index_for_cell(cell)
    if cell.transcription_field_id && cell.transcription_field.present?
      if cell.transcription_field.input_type == 'spreadsheet'
        index = @raw_headings.index(spreadsheet_heading_to_indexable(cell.transcription_field_id, cell.header))
      else
        index = (@raw_headings.index(cell.transcription_field_id))
      end
    end
    index = (@raw_headings.index(cell.header)) unless index
    index = (@raw_headings.index(cell.header.strip)) unless index

    index
  end


  def cell_data(array, raw_headings, data_cells)
    array.each do |cell|
      index = index_for_cell(cell)
      target = index *2
      data_cells[target] = XmlSourceProcessor.cell_to_plaintext(cell.content)
      data_cells[target+1] = XmlSourceProcessor.cell_to_subject(cell.content)
    end
  end





end
