class CreateBulkExports < ActiveRecord::Migration[5.0]

  def change
    create_table :bulk_exports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.string :status
      t.boolean :plaintext_verbatim_page
      t.boolean :plaintext_verbatim_work
      t.boolean :plaintext_emended_page
      t.boolean :plaintext_emended_work
      t.boolean :plaintext_searchable_page
      t.boolean :plaintext_searchable_work
      t.boolean :tei_work
      t.boolean :html_page
      t.boolean :html_work
      t.boolean :subject_csv_collection
      t.boolean :table_csv_collection
      t.boolean :table_csv_work

      t.timestamps
    end
  end

end
