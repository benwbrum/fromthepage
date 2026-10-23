class CreateSegmentationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :segmentation_logs do |t|
      t.references :page, null: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.integer :work_id, null: false
      t.string :model, null: false
      t.string :status, null: false, default: 'finished'
      t.boolean :is_first_page_candidate
      t.text :error_message
      t.json :metadata, null: true

      t.timestamps
    end

    add_index :segmentation_logs, :work_id
  end
end
