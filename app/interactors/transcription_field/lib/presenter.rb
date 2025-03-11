class TranscriptionField::Lib::Presenter
  def initialize(view_context:, collection:, page: nil, edit_action: false)
    @view_context = view_context
    @collection   = collection
    @page         = page
    @edit_action  = edit_action

    @transcription_fields = @collection.transcription_fields
                                       .includes(:spreadsheet_columns)
                                       .order(:line_number, :position)

    @spreadsheet_columns = SpreadsheetColumn.where(transcription_field_id: @transcription_fields.select(:id))
                                            .order(:position)
  end

  def formatted_fields
    return @formatted_fields if defined?(@formatted_fields)

    @formatted_fields = []
    grouped_fields = @transcription_fields.group_by(&:line_number)

    grouped_fields.each_value do |transcription_fields|
      page_number = transcription_fields.map(&:page_number).uniq.first

      next unless (@page && (page_number.nil? || page_number == @page.position)) || @edit_action

      fields = []

      count =  transcription_fields.size
      width = (100.0 / count).round(5)

      transcription_fields.each do |field|
        values = @page&.transcription_json&.dig(field.id.to_s)

        if field.input_type == 'spreadsheet' && values.blank?
          default_row = (spreadsheet_columns_map[field.id] || []).map do |col|
            row_json = {}
            row_json[col.id] = nil

            row_json
          end
          values = [default_row]
        end

        fields << {
          field: field,
          width: field.percentage.presence || width,
          values: values
        }
      end

      @formatted_fields << fields
    end

    @formatted_fields
  end

  def generate_field_input(field_id:, content:)
    field = transcription_fields_map[field_id]
    input_name = "fields[#{field.id}][#{field.label.parameterize}]"
    label = @view_context.label_tag(field.label.parameterize, field.label)

    case field.input_type
    when 'instruction'
      return @view_context.content_tag(:div, id: input_name, class: 'field-instructions') do
        @view_context.content_tag(:h5, I18n.t('transcription_field.field_layout.instructions')) + @view_context.content_tag(:p, field.label)
      end
    when 'spreadsheet'
      return @view_context.render partial: '/shared/handsontable',
                                  locals: {
                                    transcription_field: field,
                                    spreadsheet_columns: spreadsheet_columns_map[field.id] || [],
                                    content: content
                                  }
    when 'date'
      input = @view_context.text_field_tag(
        input_name,
        content,
        class: 'field-input edtf',
        data: { inputmask: '"alias": "datetime", "inputFormat": "isoDate"' }
      )
    when 'select'
      options = field.options&.split(';')
      input = @view_context.select_tag(
        input_name,
        @view_context.options_for_select(options, content),
        class: 'field-input'
      )
    when 'description'
      input = @view_context.hidden_field_tag(
        input_name,
        content,
        class: 'field-input'
      )
    when 'alt text'
      input = @view_context.text_area_tag(
        input_name,
        content,
        class: 'field-input alt-text',
        maxlength: '255'
      )
      input += @view_context.content_tag(:div, class: 'character-count')
    when 'textarea'
      input = @view_context.text_area_tag(input_name, content, class: 'field-input')
    else
      input = @view_context.text_field_tag(input_name, content, class: 'field-input')
    end

    label + input
  end

  private

  def transcription_fields_map
    @transcription_fields_map ||= @transcription_fields.index_by(&:id)
  end

  def spreadsheet_columns_map
    @spreadsheet_columns_map ||= @spreadsheet_columns.group_by(&:transcription_field_id)
  end

  def view_context
    @view_context ||= ActionView::Base.new
  end
end
