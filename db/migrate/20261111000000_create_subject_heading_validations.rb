# Validation is a separate, optional task that never saves headings to the field,
# so it gets its own record instead of living on the saved inventory.
class CreateSubjectHeadingValidations < ActiveRecord::Migration[7.2]
  def change
    create_table :subject_heading_validations do |t|
      t.references :transcription_field, type: :integer, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.string :filename, null: false
      t.integer :row_count, null: false
      t.text :source_rows, limit: 16.megabytes - 1, null: false
      t.text :report_csv, limit: 16.megabytes - 1
      t.string :status, null: false, default: 'queued'
      t.string :token
      t.text :error_message
      t.integer :processed_count, null: false, default: 0
      t.integer :total_count, null: false, default: 0
      t.datetime :completed_at
      t.datetime :notified_at
      t.timestamps
    end

    change_table :subject_heading_inventories, bulk: true do |t|
      t.remove :report_csv, type: :text, limit: 16.megabytes - 1
      t.remove :validation_status, type: :string, null: false, default: 'not_requested'
      t.remove :validation_token, type: :string
      t.remove :validation_error, type: :text
      t.remove :completed_at, type: :datetime
      t.remove :notified_at, type: :datetime
    end
  end
end
