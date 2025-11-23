class CreateSuspiciousBehaviors < ActiveRecord::Migration[7.2]
  def change
    create_table :suspicious_behaviors do |t|
      t.references :user, null: false, foreign_key: true
      t.references :page, null: true, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.references :deed, null: true, foreign_key: true
      t.string :behavior_type, null: false
      t.json :metadata
      t.datetime :flagged_at, null: false
      t.datetime :resolved_at, null: true
      t.references :resolved_by_user, null: true, foreign_key: { to_table: :users }
      t.string :status, default: 'pending', null: false

      t.timestamps
    end

    add_index :suspicious_behaviors, [:user_id, :behavior_type, :flagged_at]
    add_index :suspicious_behaviors, [:collection_id, :status]
    add_index :suspicious_behaviors, :status
  end
end
