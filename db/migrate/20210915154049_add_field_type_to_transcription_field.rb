class AddFieldTypeToTranscriptionField < ActiveRecord::Migration[6.0]

  def change
    add_column :transcription_fields, :field_type, :string, default: TranscriptionField::FieldType::TRANSCRIPTION
  end

end
