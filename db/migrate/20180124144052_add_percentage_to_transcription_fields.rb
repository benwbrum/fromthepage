class AddPercentageToTranscriptionFields < ActiveRecord::Migration
  def change
    add_column :transcription_fields, :percentage, :integer
  end
end
