module TranscriptionFieldHelper
  def field_order(collection)
    @fields = collection.transcription_fields.order(:line_number).order(:position).group_by(&:line_number)
  end

  def field_layout(array)
    @field_array = array
    count = @field_array.count
    @width = 100/count unless count == nil
  end

end