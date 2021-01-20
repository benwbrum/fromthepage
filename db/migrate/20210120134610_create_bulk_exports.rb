class CreateBulkExports < ActiveRecord::Migration[5.0]
  def change
    create_table :bulk_exports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.string :zip_file
      t.string :status
      t.boolean :plaintext_verbatim
      t.boolean :plaintext_emended
      t.boolean :plaintext_searchable
      t.boolean :tei
      t.boolean :html
      t.boolean :subject_csv
      t.boolean :field_csv
      t.boolean :page_level
      t.boolean :work_level
      t.boolean :collection_level

      t.timestamps
    end
  end
end
