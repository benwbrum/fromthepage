class AddPageNumberToTranscriptionFields < ActiveRecord::Migration
  def change
    add_column :transcription_fields, :page_number, :integer
  end
end
