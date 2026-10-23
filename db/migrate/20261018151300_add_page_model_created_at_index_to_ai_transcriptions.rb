class AddPageModelCreatedAtIndexToAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    add_index :ai_transcriptions,
              [:page_id, :model, :created_at],
              name: 'index_ai_transcriptions_on_page_model_created_at'
  end
end
