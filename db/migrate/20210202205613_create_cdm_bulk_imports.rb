class CreateCdmBulkImports < ActiveRecord::Migration[5.0]

  def change
    create_table :cdm_bulk_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :ocr_correction, default: false
      t.string :collection_param, null: false, foreign_key: true
      t.text :cdm_urls

      t.timestamps
    end
  end

end
