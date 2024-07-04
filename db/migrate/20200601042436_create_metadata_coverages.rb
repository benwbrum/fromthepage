class CreateMetadataCoverages < ActiveRecord::Migration[5.0]

  def change
    create_table :metadata_coverages do |t|
      t.string :key
      t.integer :count, default: 0
      t.integer :collection_id

      t.timestamps
    end
  end

end
