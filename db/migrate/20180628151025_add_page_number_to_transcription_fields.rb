class AddPageNumberToTranscriptionFields < ActiveRecord::Migration[5.2]
  def change
    add_column :transcription_fields, :page_number, :integer
  end
end
