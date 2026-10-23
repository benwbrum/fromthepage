class AddPageIdAndIdIndexToAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    add_index :ai_transcriptions, [:page_id, :id], name: 'index_ai_transcriptions_on_page_id_and_id'
  end
end
