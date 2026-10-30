# frozen_string_literal: true

module TranscriptionFieldHelper
  def field_input_type_options(input_types)
    labels = {
      'text' => t('transcription_field.input_types.text'),
      'select' => t('transcription_field.input_types.select'),
      'date' => t('transcription_field.input_types.date'),
      'multiselect' => t('transcription_field.input_types.multiselect'),
      'textarea' => t('transcription_field.input_types.textarea'),
      'instruction' => t('transcription_field.input_types.instruction'),
      'alt text' => t('transcription_field.input_types.alt_text'),
      'description' => t('transcription_field.input_types.description'),
      'spreadsheet' => t('transcription_field.input_types.spreadsheet'),
      'subject_headings' => t('transcription_field.input_types.subject_headings'),
      'numeric' => t('transcription_field.input_types.numeric'),
      'checkbox' => t('transcription_field.input_types.checkbox')
    }
    input_types.map { |input_type| [labels.fetch(input_type), input_type] }
  end

  def metadata_field_order(collection)
    @fields = collection.metadata_fields.order(:line_number).order(:position).group_by(&:line_number)
  end

  def subject_heading_options(field, selected)
    inventory = field.subject_heading_inventory
    headings = inventory ? inventory.subject_headings.order(:id).pluck(:heading) : []
    headings | Array(selected)
  end

  def field_layout(array)
    count = array.count
    @width = (100.0 / count).round(5) unless count.nil?
    ids = array.map(&:id)
    @values = []
    @values = ids.map { |id| @page&.table_cells&.find_by(transcription_field_id: id) }

    @field_array = array.zip(@values)
  end
end
