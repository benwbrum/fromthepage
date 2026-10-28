class AddPerformanceIndicesFor5923 < ActiveRecord::Migration[7.2]
  def change
    add_index :ai_transcriptions, [:page_id, :status, :created_at], if_not_exists: true
    add_index :works, [:collection_id, :title], length: { title: 255 }, if_not_exists: true
    add_index :deeds, [:updated_at, :work_id], if_not_exists: true
  end
end
