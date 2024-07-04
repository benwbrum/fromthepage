class AddRowHighlightToTranscriptionField < ActiveRecord::Migration[5.0]

  def change
    add_column :transcription_fields, :row_highlight, :boolean, default: false
  end

end
