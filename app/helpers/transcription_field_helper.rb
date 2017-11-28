module TranscriptionFieldHelper
  def field_layout(collection)
    @fields = collection.transcription_fields
  end
end