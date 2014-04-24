class CreateOmekaCollections < ActiveRecord::Migration
  def change
    create_table :omeka_collections do |t|
      t.integer :omeka_id
      t.integer :collection_id
      t.string :title
      t.string :description
      t.integer :omeka_site_id

      t.timestamps
    end
  end
end
