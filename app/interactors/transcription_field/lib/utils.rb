class TranscriptionField::Lib::Utils
  def self.table_cells_to_field_cells(page:, grouped_transcription_fields:, spreadsheet_columns_map:)
    field_cells = {}
    grouped_transcription_fields.each_value do |fields|
      page_number = fields.map(&:page_number).uniq.first

      next unless page_number.nil? || page.position == page_number

      fields.each do |field|
        next if field.input_type == 'instruction'

        value = {}

        if field.input_type == 'spreadsheet'
          table_cells_by_row = page.table_cells.where(transcription_field: field.id).group_by(&:row)
          spreadsheet_columns = spreadsheet_columns_map[field.id]
          cell_contents = []

          table_cells_by_row.each_value do |row|
            content = []

            spreadsheet_columns.each do |column|
              cell = row.detect { |c| c.header == column.label }

              content << cell&.content || ''
            end

            cell_contents << content
          end

          value[field.label] = cell_contents.to_json
        else
          table_cell = page.table_cells.find_by(transcription_field_id: field.id)

          next if table_cell.nil?

          value[table_cell.header] = table_cell.content
        end

        field_cells[field.id.to_s] = value
      end
    end

    field_cells
  end

  def self.parse_fields(page:, field_cells:)
    return page if field_cells.blank?

    source_text = String.new
    transcription_json = {}
    transcription_fields = TranscriptionField.includes(:spreadsheet_columns)
                                             .where(id: field_cells.keys)
                                             .order(:line_number, :position)
    transcription_fields_map = transcription_fields.index_by(&:id)

    field_cells.each do |field_id, field_data|
      field = transcription_fields_map[field_id.to_i]

      if field.input_type == 'spreadsheet'
        json_value, string_value = parse_spreadsheet(field: field, field_data: field_data)
        transcription_json[field_id.to_i] = json_value
        source_text += string_value
      else
        field_data.each do |cell_key, cell_value|
          # broken tags or actual < / > signs
          cell_value = ERB::Util.html_escape(cell_value) if cell_value.scan('<').count != cell_value.scan('>').count

          cell_key = "#{cell_key}#{field.input_type == 'description' ? ' ' : ': '}"
          source_text << "<span class=\"field__label\">#{cell_key}</span>#{cell_value}\n\n"

          transcription_json[field_id.to_i] = cell_value
        end
      end
    end

    page.transcription_json = transcription_json
    page.source_text = source_text

    page
  end

  def self.parse_spreadsheet(field:, field_data:)
    spreadsheet_columns = field.spreadsheet_columns.order(:position)
    parsed_cell_data = JSON.parse(field_data.values.first)

    rows = []

    source_text = String.new
    source_text << '<table class="tabular"><thead>'
    spreadsheet_columns.each do |column|
      source_text << "<th>#{column.label}</th>"
    end
    source_text << '</thead><tbody>'

    parsed_cell_data.each do |row|
      next unless row.detect(&:present?)

      row_json = {}
      formatted_row = '<tr>'

      spreadsheet_columns.each_with_index do |column, column_index|
        cell_value = row[column_index]

        if cell_value.blank?
          cell_value = ''
        elsif cell_value.to_s.scan('<').count != cell_value.to_s.scan('>').count
          # broken tags or actual < / > signs
          cell_value = ERB::Util.html_escape(cell_value)
        end

        cell_value = ActiveRecord::Type::Boolean.new.cast(cell_value) if column.input_type == 'checkbox'

        row_json[column.id] = cell_value
        formatted_row << "<td>#{cell_value}</td>"
      end
      formatted_row << '</tr>'

      rows << row_json
      source_text << formatted_row
    end

    source_text << '</tbody></table>'

    [rows, source_text]
  end
end
