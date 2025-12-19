# frozen_string_literal: true

module TranscriptionFieldHelper
  def metadata_field_order(collection)
    @fields = collection.metadata_fields.order(:line_number).order(:position).group_by(&:line_number)
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
