class AddPercentageToTranscriptionFields < ActiveRecord::Migration[5.0]

  def change
    add_column :transcription_fields, :percentage, :integer
  end

end
