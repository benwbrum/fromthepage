class AddStatusIndexesToAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    add_index :ai_transcriptions, :status, name: 'index_ai_transcriptions_on_status'
    add_index :ai_transcriptions, [:status, :updated_at], name: 'index_ai_transcriptions_on_status_and_updated_at'
  end
end
