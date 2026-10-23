class CreateSuspiciousBehaviorsTable < ActiveRecord::Migration[7.2]
  def change
    create_table :suspicious_behaviors do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.references :page, null: true, foreign_key: { on_delete: :nullify }, type: :integer
      t.references :collection, null: true, foreign_key: { on_delete: :nullify }, type: :integer

      t.json :metadata, null: true

      # Types: [:large_paste, :high_wpm, :chatgpt_tell, :low_backspace, :no_image_adjustment]
      t.string :behavior_type, null: false

      # Types: [:pending, :confirmed, :dismissed]
      t.string :status, null: false, default: :pending

      t.datetime :resolved_at, null: true
      t.references :resolved_by_user, null: true, foreign_key: { to_table: :users, on_delete: :nullify }, type: :integer

      t.timestamps
    end
  end
end
