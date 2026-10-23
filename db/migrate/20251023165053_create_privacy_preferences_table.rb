class CreatePrivacyPreferencesTable < ActiveRecord::Migration[7.2]
  def up
    create_table :privacy_preferences do |t|
      t.integer :user_id, null: false
      t.boolean :recorded, default: false, null: false

      t.boolean :analytics, default: false, null: false
      t.boolean :marketing, default: false, null: false

      t.index :user_id, unique: true
      t.foreign_key :users, column: :user_id, on_delete: :cascade
    end
  end

  def down
    drop_table :privacy_preferences
  end
end
