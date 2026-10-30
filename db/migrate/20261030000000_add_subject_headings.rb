class AddSubjectHeadings < ActiveRecord::Migration[7.2]
  def change
    create_table :subject_heading_inventories do |t|
      t.references :transcription_field, type: :integer, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.string :filename, null: false
      t.integer :row_count, null: false
      t.text :source_rows, limit: 16.megabytes - 1, null: false
      t.text :report_csv, limit: 16.megabytes - 1
      t.string :validation_status, null: false, default: 'not_requested'
      t.string :validation_token
      t.text :validation_error
      t.datetime :completed_at
      t.datetime :notified_at
      t.timestamps
    end

    create_table :subject_headings do |t|
      t.references :subject_heading_inventory, null: false, foreign_key: { on_delete: :cascade }, index: { name: 'index_headings_on_inventory' }
      t.string :heading, limit: 1000, null: false
      t.string :uri, limit: 1000
      t.string :normalized_key, limit: 64, null: false
    end
    add_index :subject_headings, [:subject_heading_inventory_id, :normalized_key], unique: true, name: 'index_headings_on_inventory_and_key'
    add_column :transcription_fields, :subject_heading_instructions, :text
    add_column :ai_work_metadata, :subject_heading_candidates, :text, limit: 16.megabytes - 1
  end
end
