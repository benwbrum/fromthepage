class AddOffsetsToTranscriptionField < ActiveRecord::Migration[5.0]

  def change
    add_column :transcription_fields, :top_offset, :float, default: 0.0
    add_column :transcription_fields, :bottom_offset, :float, default: 1.0
  end

end
