class CreateCdmExportSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :cdm_export_settings do |t|
      t.integer :collection_id, null: false
      t.string  :transcript_source,     default: 'human_only', null: false
      t.string  :fulltext_field
      t.boolean :include_ai_provenance, default: false, null: false
      t.string  :ai_provenance_field
      t.boolean :prepend_ai_warning,    default: false, null: false
      t.timestamps
    end

    add_index :cdm_export_settings, :collection_id, unique: true
    add_foreign_key :cdm_export_settings, :collections
  end
end
