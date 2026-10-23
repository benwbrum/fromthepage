class AddDashboardIndexToAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    add_index :ai_transcriptions,
              [:created_at, :model, :status],
              name: 'idx_ai_transcriptions_dashboard'
  end
end
