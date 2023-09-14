class AddTypeIndexToDeeds < ActiveRecord::Migration[6.0]
  def change
    add_index :deeds, [:collection_id, :deed_type, :created_at], order: { created_at: :desc }
    add_index :deeds, [:work_id, :deed_type, :user_id, :created_at], order: { created_at: :desc }
  end
end
