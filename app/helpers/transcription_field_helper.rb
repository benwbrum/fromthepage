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

  # The field's vocabulary, plus saved values and AI-suggested headings that are no longer in it,
  # so they stay selectable.
  def subject_heading_options(field, selected, suggested = [])
    inventory = field.subject_heading_inventory
    headings = inventory ? inventory.subject_headings.order(:id).pluck(:heading) : []
    headings | Array(selected) | Array(suggested)
  end

  # Headings the work's finished AI drafts suggest for a subject heading field
  def ai_suggested_headings(field)
    return [] unless @work&.ai_metadata_draft_available?

    @work.finished_ai_work_metadata_by_engine.values.flat_map { |draft| Array(draft.draft_values[field.id.to_s]) }.uniq
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
