class AddStartRowsToTranscriptionField < ActiveRecord::Migration[6.0]

  def change
    add_column :transcription_fields, :starting_rows, :int
  end

end
