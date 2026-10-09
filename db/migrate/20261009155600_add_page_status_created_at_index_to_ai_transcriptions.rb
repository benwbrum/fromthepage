class AddPageStatusCreatedAtIndexToAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    add_index :ai_transcriptions, [:page_id, :status, :created_at]
  end
end
