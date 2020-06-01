class CreateMetadataCoverages < ActiveRecord::Migration[6.0]
  def change
    create_table :metadata_coverages do |t|
      t.string :key
      t.integer :count
      t.references :collection, null: false, foreign_key: true

      t.timestamps
    end
  end
end
