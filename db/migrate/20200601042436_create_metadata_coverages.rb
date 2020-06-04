class CreateMetadataCoverages < ActiveRecord::Migration[6.0]
  def change
    create_table :metadata_coverages do |t|
      t.string :key
      t.integer :count

      # This replaces t.references :collection, foreign_key: true
      t.integer :collection_id, null: false, index: true

      t.timestamps
    end

    # This replaces t.references :collection, foreign_key: true
    add_foreign_key :metadata_coverages, :collections
  end
end
