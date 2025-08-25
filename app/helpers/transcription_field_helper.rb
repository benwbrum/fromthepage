# frozen_string_literal: true

module TranscriptionFieldHelper
  def field_order(collection)
    @fields = collection.transcription_fields.order(:line_number).order(:position).group_by(&:line_number)
  end

  def metadata_field_order(collection)
    @fields = collection.metadata_fields.order(:line_number).order(:position).group_by(&:line_number)
  end

  def field_layout(array)
    count = array.count
    @width = (100.0 / count).round(5) unless count == nil
    ids = array.map { |a| a.id }
    @values = []
    if @page
      ids.each do |id|
        @values << @page.table_cells.find_by(transcription_field_id: id) || nil
      end
    else
      @values = Array.new(ids.count, nil)
    end
    @field_array = array.zip(@values)
  end

  def generate_field_input(field, cell)
    input_name = formatted_field_name(field)

    label = label_tag(field.label.parameterize, field.label)

    content = cell&.content

    case field.input_type
    when 'text'
      input = text_field_tag(input_name, content, class: 'field-input')
    when 'date'
      input = text_field_tag(input_name, content, class: 'field-input edtf',
                                                  data: { inputmask: '"alias": "datetime", "inputFormat": "isoDate"' })
    when 'select'
      options = field.options&.split(';')
      input = select_tag(input_name, options_for_select(options, content), class: 'field-input')
    when 'description'
      input = hidden_field_tag(input_name, content, class: 'field-input')
    when 'alt text'
      input = text_area_tag(input_name, content, class: 'field-input alt-text', maxlength: '255') +
              content_tag(:div, class: 'character-count')
    else
      input = text_area_tag(input_name, content, class: 'field-input')
    end

    label + input
  end

  def formatted_field_name(field)
    "fields[#{field.id}][#{field.label.parameterize}]"
  end
end
