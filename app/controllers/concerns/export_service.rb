module ExportService
  include AbstractXmlHelper
  include StaticSiteExporter
  include OwnerExporter
  include AdminExporter
  include ContributorHelper
  require 'subject_exporter'
  require 'subject_details_exporter'

  def path_from_work(work, original_filenames=false)
    if original_filenames && !work.uploaded_filename.blank?
      dirname = File.basename(work.uploaded_filename).sub(File.extname(work.uploaded_filename), '')
    else
      dirname = work.slug.truncate(200, omission: "")
    end

    dirname
  end

  def add_readme_to_zip(work:, out:, by_work:, original_filenames:)
    dirname = path_from_work(work)
    readme = "#{Rails.root}/doc/zip/README"
    file = File.open(readme, "r")
    path = File.join dirname, 'README.txt'
    out.put_next_entry path
    out.write file.read
  end

  def export_printable_to_zip(work, edition, output_format, out, by_work, original_filenames, preserve_lb, include_metadata, include_contributors)
    return if work.pages.count == 0

    dirname = path_from_work(work)
    case edition
    when "facing"
      path = File.join dirname, 'printable', "facing_edition.pdf"
    when "text"
      path = File.join dirname, 'printable', "text.#{output_format}"
    when "text_only"
      path = File.join dirname, 'printable', "text_only.#{output_format}"
    end

    tempfile = export_printable(work, edition, output_format, preserve_lb, include_metadata, include_contributors)
    out.put_next_entry(path)
    out.write(IO.read(tempfile))
  end

  def export_printable(work, edition, format, preserve_lb, include_metadata, include_contributors)
    # render to a string
    rendered_markdown =
      ApplicationController.new.render_to_string(
        template: '/export/facing_edition.html',
        layout: false,
        assigns: {
          collection: work.collection,
          work: work,
          edition_type: edition,
          output_type: format,
          preserve_linebreaks: preserve_lb,
          include_metadata: include_metadata,
          include_contributors: include_contributors
        }
      )

    # write the string to a temp directory
    temp_dir = File.join(Rails.root, 'public', 'printable')
    Dir.mkdir(temp_dir) unless Dir.exist? temp_dir

    time_stub = Time.now.gmtime.iso8601.gsub(/\D/,'')
    temp_dir = File.join(temp_dir, time_stub)
    Dir.mkdir(temp_dir) unless Dir.exist? temp_dir

    file_stub = "#{@work.slug.gsub('-','_')}_#{time_stub}"
    md_file = File.join(temp_dir, "#{file_stub}.md")
    tex_file = File.join(temp_dir, "#{file_stub}.tex")

    if format == 'pdf'
      output_file = File.join(temp_dir, "#{file_stub}.pdf")
    elsif format == 'doc'
      output_file = File.join(temp_dir, "#{file_stub}.docx")
    end

    File.write(md_file, rendered_markdown)

    # run pandoc against the temp directory
    log_file = File.join(temp_dir, "#{file_stub}.log")

    # Convert to tex
    cmd = "pandoc --from markdown+superscript+pipe_tables -o #{tex_file} #{md_file} --verbose --abbreviations=/dev/null -V colorlinks=true > #{log_file} 2>&1"
    puts cmd
    logger.info(cmd)
    system(cmd)

    # Preprocess
    tex_content = File.read(tex_file)
    modified_content = tex_content.gsub('\textquotesingle ', "'")
    File.open(tex_file, 'w') { |file| file.write(modified_content) }

    # Convert to final format
    cmd = "pandoc -o #{output_file} #{tex_file} --pdf-engine=xelatex --verbose --abbreviations=/dev/null -V colorlinks=true > #{log_file} 2>&1"
    puts cmd
    logger.info(cmd)
    system(cmd)

    puts File.read(log_file)

    output_file
  end



  def export_owner_mailing_list_csv(out:, owner:)
    path = "mailing_list.csv"
    out.put_next_entry(path)
    out.write(owner_mailing_list_csv(owner))
  end

  def export_owner_detailed_activity_csv(out:, owner:, report_arguments:)
    path = "all_collaborator_time.csv"
    out.put_next_entry(path)
    out.write(detailed_activity_csv(owner, report_arguments["start_date"].to_datetime, report_arguments["end_date"].to_datetime))
  end

  def export_admin_searches_csv(out:, report_arguments:)
    path = "admin_searches.csv"
    out.put_next_entry(path)
    out.write(admin_searches_csv(report_arguments["start_date"].to_datetime, report_arguments["end_date"].to_datetime))
  end

  def export_collection_activity_csv(out:, collection:, report_arguments:)
    path = "collection_detailed_activity.csv"
    out.put_next_entry(path)
    out.write(collection_activity_csv(collection, report_arguments["start_date"].to_datetime, report_arguments["end_date"].to_datetime))
  end

  def export_collection_contributors_csv(out:, collection:, report_arguments:)
    path = "collection_contributors_activity.csv"
    out.put_next_entry(path)
    out.write(collection_contributors_csv(collection, report_arguments["start_date"].to_datetime, report_arguments["end_date"].to_datetime))
  end

  def export_work_metadata_csv(out:, collection:)
    path = "work_metadata.csv"
    out.put_next_entry(path)
    out.write(export_work_metadata_as_csv(collection))
  end

  def export_subject_csv(out:, collection:, work:)
    path = "subject_index.csv"
    out.put_next_entry(path)
    out.write(collection.export_subject_index_as_csv(work))
  end

  def export_subject_details_csv(out:, collection:)
    path = "subject_details.csv"
    out.put_next_entry(path)
    out.write(collection.export_subject_details_as_csv)
  end

  def export_table_csv_collection(out:, collection:)
    path = "fields_and_tables.csv"
    out.put_next_entry(path)
    out.write(export_tables_as_csv(collection))
  end

  def export_table_csv_work(out:, work:, by_work:, original_filenames:)
    if by_work
      path = File.join(path_from_work(work, original_filenames), 'csv', "fields_and_tables.csv")
    else
      path = File.join("fields_and_tables", "#{path_from_work(work, original_filenames)}.csv")
    end
    out.put_next_entry(path)
    out.write(export_tables_as_csv(work))
  end

  def export_collection_notes_csv(out:, collection:)
    path = "collection_notes.csv"
    out.put_next_entry(path)
    out.write(export_notes_as_csv(collection))
  end

  def export_tei(work:, out:, export_user:, by_work:, original_filenames:)
    if by_work
      path = File.join(path_from_work(work, original_filenames), 'tei', "tei.xml")
    else
      path = File.join("tei", "#{path_from_work(work, original_filenames)}.xml")
    end
    out.put_next_entry path
    out.write work_to_tei(work, export_user)
  end

  def export_plaintext_transcript(work:, name:, out:, by_work:, original_filenames:)
    if by_work
      path = File.join(path_from_work(work, original_filenames), 'plaintext', "#{name}_transcript.txt")
    else
      path = File.join("plaintext_transcript_#{name}", "#{path_from_work(work, original_filenames)}.txt")
    end

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

  def export_plaintext_translation(work:, name:, out:, by_work:, original_filenames:)
    if by_work
      path = File.join(path_from_work(work, original_filenames), 'plaintext', "#{name}_translation.txt")
    else
      path = File.join("plaintext_translation_#{name}", "#{path_from_work(work, original_filenames)}.txt")
    end

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

  def export_plaintext_transcript_pages(name:, out:, page:, by_work:, original_filenames:, index:)
    if by_work
      if original_filenames == :zero_index
        path = File.join(path_from_work(page.work, original_filenames), "plaintext", "#{name}_transcript_pages", "#{index}.txt")
      else
        path = File.join(path_from_work(page.work, original_filenames), "plaintext", "#{name}_transcript_pages", "#{page.title}.txt")
      end
    else
      path = File.join("plaintext_#{name}_transcript_pages", "#{path_from_work(page.work, original_filenames)}_#{page.title}.txt")
    end

    case name
    when "verbatim"
      out.put_next_entry path
      out.write page.verbatim_transcription_plaintext unless page.status_blank?
    when "expanded"
      if page.collection.subjects_disabled
        out.put_next_entry path
        out.write page.emended_transcription_plaintext unless page.status_blank?
      end
    when "searchable"
      out.put_next_entry path
      out.write page.search_text unless page.status_blank?
    end
  end

  def export_plaintext_translation_pages(name:, out:, page:, by_work:, original_filenames:)
    if by_work
      path = File.join(path_from_work(page.work, original_filenames), 'plaintext', "#{name}_translation_pages", "#{page.title}.txt")
    else
      path = File.join("plaintext_#{name}_translation_pages", "#{path_from_work(page.work, original_filenames)}_#{page.title}.txt")
    end

    if @work.supports_translation?
      case name
      when "verbatim"
        out.put_next_entry path
        out.write page.verbatim_translation_plaintext unless page.status_blank?
      when "expanded"
        if page.collection.subjects_disabled
          out.put_next_entry path
          out.write page.emended_translation_plaintext unless page.status_blank?
        end
      end
    end
  end

  def export_view(work:, name:, out:, export_user:, by_work:, original_filenames:)
    if by_work
      path = File.join(path_from_work(work, original_filenames), 'html', "#{name}.html")
    else
      path = File.join("html_#{name}", "#{path_from_work(work, original_filenames)}.html")
    end

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

  def export_html_full_pages(out:, page:, by_work:, original_filenames:)
    if by_work
      path = File.join(path_from_work(page.work, original_filenames), 'html', 'full_pages', "#{page.title}.html")
    else
      path = File.join("html_full_pages", "#{path_from_work(page.work, original_filenames)}_#{page.title}.html")
    end


    out.put_next_entry path

    page_view = xml_to_html(page.xml_text, true, false, page.work.collection)
    out.write page_view unless page.status_blank?
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
    renamed_cell_headings = TableCell.where(work_id: ids).where("transcription_field_id is not null").pluck(Arel.sql('DISTINCT header')) - collection.transcription_fields.pluck(:label)
    markdown_cell_headings = TableCell.where(work_id: ids).where("transcription_field_id is null").pluck(Arel.sql('DISTINCT header'))
    cell_headings = orphan_cell_headings + markdown_cell_headings

    @raw_headings = (field_headings + cell_headings + renamed_cell_headings).uniq
    @indexable_headings = @raw_headings.map { |e| e.is_a?(String) ? e.downcase : e }
    @headings = []

    @page_metadata_headings = collection.page_metadata_fields
    @headings += @page_metadata_headings

    input_types = collection.transcription_fields.pluck(:input_type)
    spreadsheet_count = input_types.count("spreadsheet")

    #get headings from field-based
    field_headings.each do |field_id|
      field = TranscriptionField.where(:id => field_id).first
      if field && field.input_type == 'spreadsheet'
          raw_field_index = @raw_headings.index(field_id)
          field.spreadsheet_columns.each do |column|
            raw_field_index += 1
            raw_heading = "#{field.label} #{column.label}"
            @raw_headings.insert(raw_field_index, spreadsheet_column_to_indexable(column))
            @headings << (collection.transcription_fields.present? ? "#{raw_heading}" : "#{raw_heading} (text)")
            @headings << "#{raw_heading} (subject)" unless collection.transcription_fields.present?
          end
          @raw_headings.delete(field_id)
      else
        raw_heading = field ? field.label : field_id
        @headings << (collection.transcription_fields.present? ? "#{raw_heading}" : "#{raw_heading} (text)")
        @headings << "#{raw_heading} (subject)" unless collection.transcription_fields.present?
      end
    end
    #get headings from non-field-based
    cell_headings.each do |raw_heading|
      @headings << (collection.transcription_fields.present? ? "#{raw_heading}" : "#{raw_heading} (text)")
      @headings << "#{raw_heading} (subject)" unless collection.transcription_fields.present?
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
        'Creation Date',
        'Total Pages',
        'Pages Transcribed',
        'Pages Corrected',
        'Pages Indexed',
        'Pages Translated',
        'Pages Needing Review',
        'Pages Marked Blank',
        'Contributors',
        'Contributors Name',
        'work_id'
      ]

      raw_metadata_strings = collection.works.pluck(:original_metadata)
      metadata_headers = raw_metadata_strings.map{|raw| raw.nil? ? [] : JSON.parse(raw).map{|element| element["label"] } }.flatten.uniq
      # append the headers for described metadata, read from the metadata_field configuration for the project
      static_description_headers = ['Description Status', 'Described By']
      described_headers = collection.metadata_fields.map {|field| field.label}

      csv << static_headers + metadata_headers + static_description_headers + described_headers

      collection.works.includes(:document_sets, :work_statistic, :sc_manifest).reorder(:id).each do |work|

        work_users = work.deeds.map{ |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }.uniq.join('|')
        contributors_real_names = work.deeds.map{ |d| d.user.real_name }.uniq.join(' | ')
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
          work.created_on,
          work.work_statistic.total_pages,
          work.work_statistic.transcribed_pages,
          work.work_statistic.corrected_pages,
          work.work_statistic.annotated_pages,
          work.work_statistic.translated_pages,
          work.work_statistic.needs_review,
          work.work_statistic.blank_pages,
          work_users,
          contributors_real_names,
          work.id

        ]

        unless work.original_metadata.blank?
          metadata = {}
          JSON.parse(work.original_metadata).each {|e| metadata[e['label']] = e['value'] }

          metadata_headers.each do |header|
            # look up the value for this index
            row << metadata[header]
          end
        end

        unless work.metadata_description.blank?
          # description status
          row << work.description_status
          # described by
          row << User.find(work.metadata_description_versions.pluck(:user_id)).map{|u| u.display_name}.join('; ')

          metadata = JSON.parse(work.metadata_description)
          # we rely on a consistent order of fields returned by collection.metadata_fields to prevent scrambling columns
          collection.metadata_fields.each do |field|
            element = metadata.detect{|candidate| candidate['transcription_field_id'] == field.id}
            if element
              value = element['value']
              if value.is_a? Array
                value = value.join("; ")
              end
              row << value
            else
              row << nil
            end
          end
        end

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
        'FromThePage Identifier',
        'Page Title',
        'Page Position',
        'Page URL',
        'Page Contributors',
        'Page Notes',
        'Page Status'
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
        csv = generate_csv(w, csv, col_sections, collection.transcription_fields.present?, collection)
      end

    end
    csv_string
  end

  def generate_csv(work, csv, col_sections, transcription_field_flag, collection)
    all_deeds = work.deeds

    if transcription_field_flag
      renamed_cell_headings_count = 1
      # This is a Chesterton's Fence variable -- originally it appears to have been designed
      # for field-based projects in which some field labels had been changed halfway through
      # the transcription process.  As a result, it sees spreadsheet columns as "renamed" fields.
      # We think that there is some work-around code further down to support supreadsheets.
      renamed_cell_headings = TableCell.where(work_id: work.id).where("transcription_field_id is not null").pluck(Arel.sql('DISTINCT header')) - collection.transcription_fields.pluck(:label)
      input_types = collection.transcription_fields.pluck(:input_type)
      spreadsheet_count = input_types.count("spreadsheet")
      position = input_types.index("spreadsheet")
    else
      renamed_cell_headings_count = 0
    end
    spreadsheet_field_ids = work.collection.transcription_fields.where(input_type: 'spreadsheet').order(:line_number).pluck(:id)

    work.pages.includes(:table_cells).each do |page|
      unless page.table_cells.empty?
        has_spreadsheet = page.table_cells.detect { |cell| cell.transcription_field && cell.transcription_field.input_type == 'spreadsheet' }

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
          work.id,
          page.title,
          page.position,
          page_url,
          page_contributors,
          page_notes,
          I18n.t("page.edit.page_status_#{page.status}")
        ]

        page_metadata_cells = page_metadata_cells(page)
        data_cells = Array.new(@headings.count, "")
        running_data = []

        if page.sections.blank?
          if has_spreadsheet
            grouped_hash = {}
            spreadsheet_rows_and_ids = page.table_cells.where("transcription_field_id in (?)", spreadsheet_field_ids).pluck(:transcription_field_id, :row).uniq
            spreadsheet_rows_and_ids.each_with_index do |field_id_and_row, i|
              # find the cells with this id and row
              transcription_field_id = field_id_and_row[0]
              row = field_id_and_row[1]
              grouped_hash[i+1] = page.table_cells.where(row: row, transcription_field_id: transcription_field_id).to_a
            end
            grouped_hash[1] += page.table_cells.where("transcription_field_id not in (?)", spreadsheet_field_ids).to_a
          else
            grouped_hash = page.table_cells.includes(:transcription_field).group_by(&:row)
          end

          grouped_hash.each do |row, cell_array|
            count = 0
            while count < renamed_cell_headings_count
              #get the cell data and add it to the array
              cell_data(cell_array, data_cells, transcription_field_flag, count, position, spreadsheet_count)
              if has_spreadsheet
                running_data = process_header_footer_data(data_cells, running_data, cell_array, count, position, spreadsheet_count, row)
              end
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
              count = count + 1
            end
          end

        else
          #get the table sections/headers and iterate cells within the sections
          page.sections.each_with_index do |section,rownum|
            section_title_text = XmlSourceProcessor::cell_to_plaintext(section.title) || nil
            section_title_subjects = XmlSourceProcessor::cell_to_subject(section.title) || nil
            section_title_categories = XmlSourceProcessor::cell_to_category(section.title) || nil
            section_cells = [section_title_text, section_title_subjects, section_title_categories]
            #group the table cells per section into rows
            section.table_cells.group_by(&:row).each do |row, cell_array|
              #get the cell data and add it to the array
              cell_data(cell_array, data_cells, transcription_field_flag, rownum, position, 0)
              if has_spreadsheet
                running_data = process_header_footer_data(data_cells, running_data, cell_array, row)
              end
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
    index = (@indexable_headings.index(cell.header)) unless index
    index = (@indexable_headings.index(cell.header.downcase)) unless index
    index = (@indexable_headings.index(cell.header.strip.downcase)) unless index

    index
  end


  def cell_data(array, data_cells, transcription_field_flag, count, position, spreadsheet_count)
    if transcription_field_flag
      result = array.select do |element|
        transcription_field = element.transcription_field
        transcription_field && transcription_field.input_type == 'spreadsheet'
      end
    end

    array.each do |cell|
      index = index_for_cell(cell)
      target = transcription_field_flag ? index : index *2
      data_cells[target] = XmlSourceProcessor.cell_to_plaintext(cell.content)
      data_cells[target+1] ||= XmlSourceProcessor.cell_to_subject(cell.content) unless transcription_field_flag
    end
  end

  def process_header_footer_data(data_cells, running_data, cell_array, count, position, spreadsheet_count, rownum)
    # assume that we are a spreadsheet already

    # create running data if it's our first time
    if running_data.nil?
      running_data = []
    end

    # are we in row 1?  fill the running data with non-spreadsheet fields
    if rownum == 1
      cell_array.each do |cell|
        if cell.transcription_field
          unless cell.transcription_field.input_type == 'spreadsheet'
            running_data << cell
          end
        end
      end
    else
      # are we in row 2 or greater?
      # fill data cells from running header/footer data
      cell_data(running_data, data_cells, true, count, position, spreadsheet_count)
    end

    # return the current running data
    running_data
  end

  def collection_activity_csv(collection, start_date, end_date)
    start_date = start_date.to_datetime.beginning_of_day
    end_date = end_date.to_datetime.end_of_day

    recent_activity = collection.deeds.where({created_at: start_date...end_date})
        .where(deed_type: DeedType.contributor_types)

    headers = [
      :date,
      :user,
      :user_real_name,
      :user_email,
      :deed_type,
      :page_title,
      :page_url,
      :work_title,
      :work_url,
      :comment,
      :subject_title,
      :subject_url
    ]

    rows = recent_activity.map {|d|

    note = ''
    note += d.note.title if d.deed_type == DeedType::NOTE_ADDED && !d.note.nil?

      record = [
        d.created_at,
        d.user.display_name,
        d.user.real_name,
        d.user.email,
        d.deed_type
      ]

      if d.deed_type == DeedType::ARTICLE_EDIT
        record += ['','','','','',]
        record += [
          d.article ? d.article.title : '[deleted]',
          d.article ? collection_article_show_url(d.collection.owner, d.collection, d.article) : ''
        ]
      else
        unless d.deed_type == DeedType::COLLECTION_JOINED
          pagedeeds = [
            d.page.title,
            collection_transcribe_page_url(d.page.collection.owner, d.page.collection, d.page.work, d.page),
            d.work.title,
            collection_read_work_url(d.work.collection.owner, d.work.collection, d.work),
            note,
          ]
          record += pagedeeds
          record += ['','']
        end
      end
      record
    }

    csv = CSV.generate(:headers => true) do |records|
      records << headers
      rows.each do |row|
          records << row
      end
    end

    csv
  end

  def collection_contributors_csv(collection, start_date, end_date)
    id = collection.id

    start_date = start_date.to_datetime.beginning_of_day
    end_date = end_date.to_datetime.end_of_day

    new_contributors(collection, start_date, end_date)

    headers = [
      :name,
      :user_real_name,
      :email,
      :minutes,
      :pages_transcribed,
      :page_edits,
      :page_reviews,
      :pages_translated,
      :ocr_corrections,
      :notes,
    ]

    user_time_proportional = AhoyActivitySummary.where(collection_id: @collection.id, date: [start_date..end_date]).group(:user_id).sum(:minutes)

    stats = @active_transcribers.map do |user|
      time_proportional = user_time_proportional[user.id]

      id_data = [user.display_name, user.real_name, user.email]
      time_data = [time_proportional]

      user_deeds = @collection_deeds.select { |d| d.user_id == user.id }

      user_stats = [
        user_deeds.count { |d| d.deed_type == DeedType::PAGE_TRANSCRIPTION },
        user_deeds.count { |d| d.deed_type == DeedType::PAGE_EDIT },
        user_deeds.count { |d| d.deed_type == DeedType::PAGE_REVIEWED },
        user_deeds.count { |d| d.deed_type == DeedType::PAGE_TRANSLATED },
        user_deeds.count { |d| d.deed_type == DeedType::OCR_CORRECTED },
        user_deeds.count { |d| d.deed_type == DeedType::NOTE_ADDED }
      ]

      id_data + time_data + user_stats
    end

    csv = CSV.generate(:headers => true) do |records|
      records << headers
      stats.each do |user|
          records << user
      end
    end

    csv
  end

  def export_notes_as_csv(collection)
    headers = [
      'Work Title',
      'Work Identifier',
      'FromThePage Identifier',
      'Page Title',
      'Page Position',
      'Page URL',
      'Page Contributors',
      'Page Status',
      'Note',
      'Contributor',
      'Date'
    ]

    notes = collection.notes.order(created_at: :desc)
    rows = notes.map {|n|
      page_url = url_for({:controller=>'display',:action => 'display_page', :page_id => n.page.id, :only_path => false})
      page_contributors = n.page.deeds
        .map { |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }
        .uniq.join('|')

      [
        n.work.title,
        n.work.identifier,
        n.work.id,
        n.page.title,
        n.page.position,
        page_url,
        page_contributors,
        I18n.t("page.edit.page_status_#{n.page.status}"),
        n.body,
        "#{n.user.display_name}<#{n.user.email}>",
        n.created_at
      ]
    }

    csv = CSV.generate(:headers => true) do |records|
      records << headers
      rows.each do |row|
          records << row
      end
    end
  end
end
