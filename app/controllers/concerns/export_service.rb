module ExportService
  include AbstractXmlHelper
  include StaticSiteExporter
  include OwnerExporter
  include AdminExporter
  include ContributorHelper
  require_dependency 'subject_exporter'
  require_dependency 'subject_details_exporter'

  include Rails.application.routes.url_helpers

  # Quick and dirty override to ensure default_url_options is set.
  def default_url_options
    Rails.application.config.action_mailer.default_url_options || {}
  end

  def path_from_work(work, original_filenames = false)
    if original_filenames && !work.uploaded_filename.blank?
      dirname = File.basename(work.uploaded_filename).sub(File.extname(work.uploaded_filename), '')
    else
      dirname = work.slug.truncate(200, omission: '')
    end

    dirname
  end

  def export_owner_mailing_list_csv(path:, owner:)
    write_artifact(
      base: path,
      relative: 'mailing_list.csv',
      content: owner_mailing_list_csv(owner)
    )
  end

  def export_owner_detailed_activity_csv(path:, owner:, report_arguments:)
    write_artifact(
      base: path,
      relative: 'all_collaborator_time.csv',
      content: detailed_activity_csv(owner, report_arguments['start_date'].to_datetime, report_arguments['end_date'].to_datetime)
    )
  end

  def export_admin_searches_csv(path:, report_arguments:)
    write_artifact(
      base: path,
      relative: 'admin_searches.csv',
      content: admin_searches_csv(report_arguments['start_date'].to_datetime, report_arguments['end_date'].to_datetime)
    )
  end

  def export_grover_printable_to_zip(work, path, by_work, original_filenames, preserve_lb, include_metadata, include_contributors, include_notes, source, prepend_ai_warnings)
    return if work.pages.count == 0

    dirname = path_from_work(work)
    relative = File.join dirname, 'printable', 'accessible_pdf.pdf'

    # NOTE: We only support text editions for grover
    result = Work::Export::GroverPrintable.new(
      work: work,
      edition: 'text',
      include_metadata: include_metadata,
      include_contributors: include_contributors,
      include_notes: include_notes,
      preserve_lb: preserve_lb,
      source: source&.to_sym || :human_only,
      prepend_ai_warnings: prepend_ai_warnings
    ).call

    if result.success?
      destination_path = File.join(path, relative)
      FileUtils.mkdir_p(File.dirname(destination_path))
      File.binwrite(destination_path, result.file)
    else
      raise result.full_errors
    end
  end

  def export_collection_activity_csv(path:, collection:, report_arguments:)
    write_artifact(
      base: path,
      relative: 'collection_detailed_activity.csv',
      content: collection_activity_csv(collection, report_arguments['start_date'].to_datetime, report_arguments['end_date'].to_datetime)
    )
  end

  def export_collection_contributors_csv(path:, collection:, report_arguments:)
    write_artifact(
      base: path,
      relative: 'collection_contributors_activity.csv',
      content: collection_contributors_csv(collection, report_arguments['start_date'].to_datetime, report_arguments['end_date'].to_datetime)
    )
  end

  def export_subject_csv(path:, collection:, work:)
    write_artifact(
      base: path,
      relative: 'subject_index.csv',
      content: collection.export_subject_index_as_csv(work)
    )
  end

  def export_subject_details_csv(path:, collection:)
    write_artifact(
      base: path,
      relative: 'subject_details.csv',
      content: collection.export_subject_details_as_csv
    )
  end

  def export_table_csv_collection(path:, collection:)
    relative = 'fields_and_tables.csv'

    if collection.field_based?
      result = Work::Table::ExportCsv.new(
        collection: collection,
        work_ids: collection.works.pluck(:id)
      ).call

      csv_string = result.csv_string
    else
      csv_string = export_tables_as_csv(collection)
    end

    write_artifact(
      base: path,
      relative: relative,
      content: csv_string
    )
  end

  def export_work_metadata_csv(path:, collection:)
    result = Work::Metadata::ExportCsv.new(collection: collection, works: collection.works).call
    write_artifact(
      base: path,
      relative: 'work_metadata.csv',
      content: result.csv_string
    )
  end

  def export_collection_notes_csv(path:, collection:)
    write_artifact(
      base: path,
      relative: 'collection_notes.csv',
      content: export_notes_as_csv(collection)
    )
  end

  def export_page_details_csv_collection(path:, collection:)
    write_artifact(
      base: path,
      relative: 'page_details.csv',
      content: export_page_details_as_csv(collection)
    )
  end

  def add_readme_to_zip(work:, path:, by_work:, original_filenames:)
    dirname = path_from_work(work)
    readme_path = Rails.root.join('doc', 'zip', 'README')

    write_artifact(
      base: path,
      relative: File.join(dirname, 'README.txt'),
      content: File.read(readme_path)
    )
  end

  def export_table_csv_work(path:, work:, by_work:, original_filenames:)
    relative =
      if by_work
        File.join(
          path_from_work(work, original_filenames),
          'csv',
          'fields_and_tables.csv'
        )
      else
        File.join(
          'fields_and_tables',
          "#{path_from_work(work, original_filenames)}.csv"
        )
      end

    collection = work.collection

    csv_string =
      if collection.field_based?
        result = Work::Table::ExportCsv.new(
          collection: collection,
          work_ids: [work.id]
        ).call

        result.csv_string
      else
        export_tables_as_csv(work)
      end

    write_artifact(
      base: path,
      relative: relative,
      content: csv_string
    )
  end

  def export_page_details_csv_work(path:, work:, by_work:, original_filenames:)
    relative =
      if by_work
        File.join(
          path_from_work(work, original_filenames),
          'csv',
          'page_details.csv'
        )
      else
        File.join(
          'page_details',
          "#{path_from_work(work, original_filenames)}.csv"
        )
      end

    write_artifact(
      base: path,
      relative: relative,
      content: export_page_details_as_csv(work)
    )
  end

  def export_tei(work:, path:, export_user:, by_work:, original_filenames:)
    relative =
      if by_work
        File.join(
          path_from_work(work, original_filenames),
          'tei',
          'tei.xml'
        )
      else
        File.join(
          'tei',
          "#{path_from_work(work, original_filenames)}.xml"
        )
      end

    write_artifact(
      base: path,
      relative: relative,
      content: work_to_tei(work, export_user)
    )
  end

  def export_plaintext_transcript(work:, name:, path:, by_work:, original_filenames:)
    relative =
      if by_work
        File.join(
          path_from_work(work, original_filenames),
          'plaintext',
          "#{name}_transcript.txt"
        )
      else
        File.join(
          "plaintext_transcript_#{name}",
          "#{path_from_work(work, original_filenames)}.txt"
        )
      end

    content =
      case name
      when 'verbatim'
        work.verbatim_transcription_plaintext
      when 'expanded'
        if work.collection.subjects_disabled
          work.emended_transcription_plaintext
        else
          nil
        end
      when 'searchable'
        work.searchable_plaintext
      else
        nil
      end

    unless content.nil?
      write_artifact(
        base: path,
        relative: relative,
        content: content
      )
    end
  end

  def export_plaintext_translation(work:, name:, path:, by_work:, original_filenames:)
    relative =
      if by_work
        File.join(
          path_from_work(work, original_filenames),
          'plaintext',
          "#{name}_translation.txt"
        )
      else
        File.join(
          "plaintext_translation_#{name}",
          "#{path_from_work(work, original_filenames)}.txt"
        )
      end

    if work.supports_translation?
      content =
        case name
        when 'verbatim'
          work.verbatim_translation_plaintext
        when 'expanded'
          if work.collection.subjects_disabled
            work.emended_translation_plaintext
          else
            nil
          end
        else
          nil
        end

      unless content.nil?
        write_artifact(
          base: path,
          relative: relative,
          content: content
        )
      end
    end
  end

  def export_view(work:, name:, path:, export_user:, by_work:, original_filenames:)
    relative =
      if by_work
        File.join(
          path_from_work(work, original_filenames),
          'html',
          "#{name}.html"
        )
      else
        File.join(
          "html_#{name}",
          "#{path_from_work(work, original_filenames)}.html"
        )
      end

    content =
      case name
      when 'full'
        ApplicationController.new.render_to_string(
          template: 'export/show',
          formats: [:html],
          work_id: work.id,
          layout: false,
          encoding: 'utf-8',
          assigns: {
            collection: work.collection,
            work: work,
            export_user: export_user
          })
      when 'text'
        ApplicationController.new.render_to_string(
          template: 'export/text',
          formats: [:html],
          work_id: work.id,
          layout: false,
          encoding: 'utf-8',
          assigns: {
            collection: work.collection,
            work: work,
            export_user: export_user
          })
      when 'transcript'
        ApplicationController.new.render_to_string(
          template: 'export/transcript',
          formats: [:html],
          work_id: work.id,
          layout: false,
          encoding: 'utf-8',
          assigns: {
            collection: work.collection,
            work: work,
            export_user: export_user
          })
      when 'translation'
        if work.supports_translation?
          ApplicationController.new.render_to_string(
            template: 'export/translation',
            formats: [:html],
            work_id: work.id,
            layout: false,
            encoding: 'utf-8',
            assigns: {
              collection: work.collection,
              work: work,
              export_user: export_user
            })
        else
          nil
        end
      else
        nil
      end

    unless content.nil?
      write_artifact(
        base: path,
        relative: relative,
        content: content
      )
    end
  end

  def export_printable_to_zip(work, edition, output_format, path, by_work, original_filenames, preserve_lb, include_metadata, include_contributors, include_notes)
    return if work.pages.count == 0

    dirname = path_from_work(work)
    relative =
      case edition
      when 'facing'
        File.join dirname, 'printable', 'facing_edition.pdf'
      when 'text'
        File.join dirname, 'printable', "text.#{output_format}"
      when 'text_only'
        File.join dirname, 'printable', "text_only.#{output_format}"
      end

    result = Work::Export::Printable.new(
      work: work,
      format: output_format,
      edition: edition,
      include_metadata: include_metadata,
      include_contributors: include_contributors,
      include_notes: include_notes,
      preserve_lb: preserve_lb
    ).call

    if result.success?
      destination_path = File.join(path, relative)
      FileUtils.mkdir_p(File.dirname(destination_path))
      FileUtils.cp(result.file, destination_path)
    else
      raise result.full_errors
    end
  end

  def export_plaintext_transcript_pages(name:, path:, page:, by_work:, original_filenames:, index:)
    relative =
      if by_work
        if original_filenames == :zero_index
          File.join(
            path_from_work(page.work, original_filenames),
            'plaintext',
            "#{name}_transcript_pages",
            "#{index}.txt"
          )
        else
          File.join(
            path_from_work(page.work, original_filenames),
            'plaintext',
            "#{name}_transcript_pages",
            "#{page.title}.txt"
          )
        end
      else
        File.join(
          "plaintext_#{name}_transcript_pages",
          "#{path_from_work(page.work, original_filenames)}_#{page.title}.txt"
        )
      end

    content =
      case name
      when 'verbatim'
        if page.status_blank?
          nil
        else
          page.verbatim_transcription_plaintext
        end
      when 'expanded'
        if page.collection.subjects_disabled && !page.status_blank?
          page.emended_transcription_plaintext
        else
          nil
        end
      when 'searchable'
        if page.status_blank?
          nil
        else
          page.search_text
        end
      else
        nil
      end

    unless content.nil?
      write_artifact(
        base: path,
        relative: relative,
        content: content
      )
    end
  end

  def export_plaintext_translation_pages(name:, path:, page:, by_work:, original_filenames:)
    relative =
      if by_work
        File.join(
          path_from_work(page.work, original_filenames),
          'plaintext', "#{name}_translation_pages",
          "#{page.title}.txt"
        )
      else
        File.join(
          "plaintext_#{name}_translation_pages",
          "#{path_from_work(page.work, original_filenames)}_#{page.title}.txt"
        )
      end

    if page.work.supports_translation?
      content =
        case name
        when 'verbatim'
          if page.status_blank?
            nil
          else
            page.verbatim_translation_plaintext
          end
        when 'expanded'
          if page.collection.subjects_disabled && !page.status_blank?
            page.emended_translation_plaintext
          else
            nil
          end
        else
          nil
        end
    end

    unless content.nil?
      write_artifact(
        base: path,
        relative: relative,
        content: content
      )
    end
  end

  def export_html_full_pages(path:, page:, by_work:, original_filenames:)
    relative =
      if by_work
        File.join(
          path_from_work(page.work, original_filenames),
          'html',
          'full_pages',
          "#{page.title}.html"
        )
      else
        File.join(
          'html_full_pages',
          "#{path_from_work(page.work, original_filenames)}_#{page.title}.html"
        )
      end

    page_view = xml_to_html(page.xml_text, true, false, page.work.collection)

    unless page.status_blank?
      write_artifact(
        base: path,
        relative: relative,
        content: page_view
      )
    end
  end

  private

  def spreadsheet_heading_to_indexable(field_id, column_label)
    { field_id => column_label }
  end

  def spreadsheet_column_to_indexable(column)
    spreadsheet_heading_to_indexable(column.transcription_field_id, column.label)
  end

  def get_headings(collection, ids)
    field_headings = collection.transcription_fields.order(:line_number, :position).where.not(input_type: 'instruction').pluck(:id)
    orphan_cell_headings = TableCell.where(work_id: ids).where('transcription_field_id not in (select id from transcription_fields)').pluck(Arel.sql('DISTINCT header'))
    renamed_cell_headings = TableCell.where(work_id: ids).where('transcription_field_id is not null').pluck(Arel.sql('DISTINCT header')) - collection.transcription_fields.pluck(:label)
    markdown_cell_headings = TableCell.where(work_id: ids).where('transcription_field_id is null').pluck(Arel.sql('DISTINCT header'))
    cell_headings = orphan_cell_headings + markdown_cell_headings

    @raw_headings = (field_headings + cell_headings + renamed_cell_headings).uniq
    @indexable_headings = @raw_headings.map { |e| e.is_a?(String) ? e.downcase : e }
    @headings = []

    @page_metadata_headings = collection.page_metadata_fields
    @headings += @page_metadata_headings

    input_types = collection.transcription_fields.pluck(:input_type)
    spreadsheet_count = input_types.count('spreadsheet')

    # get headings from field-based
    field_headings.each do |field_id|
      field = TranscriptionField.where(id: field_id).first
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
    # get headings from non-field-based
    cell_headings.each do |raw_heading|
      @headings << (collection.transcription_fields.present? ? "#{raw_heading}" : "#{raw_heading} (text)")
      @headings << "#{raw_heading} (subject)" unless collection.transcription_fields.present?
    end
    @headings
  end

  def export_tables_as_csv(table_obj)
    if table_obj.is_a?(Collection)
      collection = table_obj
      ids = table_obj.works.ids
      works = table_obj.works
    elsif table_obj.is_a?(Work)
      collection = table_obj.collection
      # need arrays so they will act equivalently to the collection works
      ids = [table_obj.id]
      works = [table_obj]
    end

    get_headings(collection, ids)

    csv_string = CSV.generate(force_quotes: true) do |csv|
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
      renamed_cell_headings = TableCell.where(work_id: work.id).where('transcription_field_id is not null').pluck(Arel.sql('DISTINCT header')) - collection.transcription_fields.pluck(:label)
      input_types = collection.transcription_fields.pluck(:input_type)
      spreadsheet_count = input_types.count('spreadsheet')
      position = input_types.index('spreadsheet')
    else
      # this variable apparently tracks how many times we should attempt to process a set of headers, designed for sparse tables
      renamed_cell_headings_count = 1
    end
    spreadsheet_field_ids = work.collection.transcription_fields.where(input_type: 'spreadsheet').order(:line_number).pluck(:id)

    work.pages.includes(:table_cells).each do |page|
      unless page.table_cells.empty?
        has_spreadsheet = page.table_cells.detect { |cell| cell.transcription_field && cell.transcription_field.input_type == 'spreadsheet' }

        page_url = collection_display_page_url(collection.owner, collection, work, page)
        page_notes = page.notes
          .map { |n| "[#{n.user.display_name}<#{n.user.email}>]: #{n.body}" }.join('|').gsub('|', '//').gsub(/\s+/, ' ')
        page_contributors = all_deeds
          .select { |d| d.page_id == page.id }
          .map { |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }
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
        data_cells = Array.new(@headings.count, '')
        running_data = []

        if page.sections.blank?
          if has_spreadsheet
            grouped_hash = {}
            spreadsheet_rows_and_ids = page.table_cells.where('transcription_field_id in (?)', spreadsheet_field_ids).pluck(:transcription_field_id, :row).uniq
            spreadsheet_rows_and_ids.each_with_index do |field_id_and_row, i|
              # find the cells with this id and row
              transcription_field_id = field_id_and_row[0]
              row = field_id_and_row[1]
              grouped_hash[i+1] = page.table_cells.where(row: row, transcription_field_id: transcription_field_id).to_a
            end
            grouped_hash[1] += page.table_cells.where('transcription_field_id not in (?)', spreadsheet_field_ids).to_a
          else
            grouped_hash = page.table_cells.includes(:transcription_field).group_by(&:row)
          end

          grouped_hash.each do |row, cell_array|
            count = 0
            while count < renamed_cell_headings_count # this is 0 and should not be!
              # get the cell data and add it to the array
              cell_data(cell_array, data_cells, transcription_field_flag, count, position, spreadsheet_count)
              if has_spreadsheet
                running_data = process_header_footer_data(data_cells, running_data, cell_array, count, position, spreadsheet_count, row)
              end
              # shift cells over if any page has sections
              if !col_sections
                section_cells = []
              else
                section_cells = ['', '', '']
              end
              # write the record to the CSV and start a new record
              csv << (page_cells + page_metadata_cells + section_cells + data_cells)
              # create a new array for the next row
              data_cells = Array.new(@headings.count, '')
              count = count + 1
            end
          end

        else
          # get the table sections/headers and iterate cells within the sections
          page.sections.each_with_index do |section, rownum|
            section_title_text = XmlSourceProcessor.cell_to_plaintext(section.title) || nil
            section_title_subjects = XmlSourceProcessor.cell_to_subject(section.title) || nil
            section_title_categories = XmlSourceProcessor.cell_to_category(section.title) || nil
            section_cells = [section_title_text, section_title_subjects, section_title_categories]
            # group the table cells per section into rows
            section.table_cells.group_by(&:row).each do |row, cell_array|
              # get the cell data and add it to the array
              cell_data(cell_array, data_cells, transcription_field_flag, rownum, position, 0)
              if has_spreadsheet
                running_data = process_header_footer_data(data_cells, running_data, cell_array, row)
              end
              # write the record to the CSV and start a new record
              csv << (page_cells + page_metadata_cells + section_cells + data_cells)
              # create a new array for the next row
              data_cells = Array.new(@headings.count, '')
            end
          end
        end
      end
  end
    csv
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

    recent_activity = collection.deeds.where({ created_at: start_date...end_date })
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

    rows = recent_activity.map { |d|
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
        record += ['', '', '', '', '']
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
            note
          ]
          record += pagedeeds
          record += ['', '']
        end
      end
      record
    }

    csv = CSV.generate(headers: true) do |records|
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
      :notes
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

    csv = CSV.generate(headers: true) do |records|
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
    rows = notes.map { |n|
      page_url =collection_display_page_url(collection.owner, collection, n.page.work, n.page)
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

    csv = CSV.generate(headers: true) do |records|
      records << headers
      rows.each do |row|
        records << row
      end
    end
  end

  def export_page_details_as_csv(page_source)
    # page_source can be either a Collection or a Work
    if page_source.is_a?(Collection)
      collection = page_source
      works = collection.works.includes(:work_statistic, :sc_manifest, :document_sets, pages: [:notes, { page_versions: :user }, { deeds: :user }])
    elsif page_source.is_a?(Work)
      collection = page_source.collection
      works = [page_source].each { |w| w.pages.includes(:notes, { page_versions: :user }, { deeds: :user }) }
    else
      return ''
    end

    # Build headers - combining page info and work metadata
    page_headers = [
      'Page URL',
      'Page Title',
      'Page Position',
      'Page Status',
      'Page Translation Status',
      'Page Contributors',
      'Page Notes Count',
      'Page Last Updated'
    ]

    work_headers = [
      'Work Title',
      'Work Identifier',
      'Work FromThePage ID',
      'Work FromThePage URL',
      'Work Description',
      'Work Total Pages',
      'Work Pages Transcribed',
      'Work Pages Corrected',
      'Work Pages Indexed',
      'Work Pages Translated',
      'Work Pages Needing Review',
      'Work Pages Marked Blank',
      'Work Contributors',
      'Work Document Sets',
      'Work Uploaded Filename',
      'Work Creation Date'
    ]

    # Get metadata headers from work original_metadata
    raw_metadata_strings = works.pluck(:original_metadata)
    metadata_headers = raw_metadata_strings
                       .compact
                       .flat_map { |raw| JSON.parse(raw).map { |element| element['label'] } }
                       .uniq

    csv_string = CSV.generate(force_quotes: true) do |csv|
      csv << (page_headers + work_headers + metadata_headers)

      works.each do |work|
        # Get work-level data that will be repeated for each page
        work_users = work.deeds.map { |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }.uniq.join('|')

        work_data = [
          work.title,
          work.identifier,
          work.id,
          collection_read_work_url(collection.owner, collection, work),
          work.description,
          work.work_statistic&.total_pages || 0,
          work.work_statistic&.transcribed_pages || 0,
          work.work_statistic&.corrected_pages || 0,
          work.work_statistic&.annotated_pages || 0,
          work.work_statistic&.translated_pages || 0,
          work.work_statistic&.needs_review || 0,
          work.work_statistic&.blank_pages || 0,
          work_users,
          work.document_sets.map(&:title).join('|'),
          work.uploaded_filename,
          work.created_on
        ]

        # Add work metadata
        work_metadata_values = []
        if work.original_metadata.present?
          metadata = {}
          JSON.parse(work.original_metadata).each { |e| metadata[e['label']] = e['value'] }

          metadata_headers.each do |header|
            work_metadata_values << metadata[header]
          end
        else
          work_metadata_values = Array.new(metadata_headers.length, nil)
        end

        # Iterate through each page in the work
        work.pages.each do |page|
          page_url = collection_display_page_url(collection.owner, collection, work, page)

          # Get page contributors
          page_contributors = page.deeds
            .select { |d| DeedType.contributor_types.include?(d.deed_type) }
            .map { |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }
            .uniq
            .join('|')

          page_data = [
            page_url,
            page.title,
            page.position,
            I18n.t("page.edit.page_status_#{page.status}"),
            work.supports_translation ? I18n.t("page.edit.page_status_#{page.translation_status}") : 'N/A',
            page_contributors,
            page.notes.count,
            page.updated_at
          ]

          csv << (page_data + work_data + work_metadata_values)
        end
      end
    end

    csv_string
  end

  def write_artifact(base:, relative:, content:)
    full = File.join(base, relative)

    FileUtils.mkdir_p(File.dirname(full))

    File.open(full, 'wb') do |f|
      f.write(content)
    end
  end
end
