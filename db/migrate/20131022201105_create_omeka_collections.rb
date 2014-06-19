class CreateOmekaCollections < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.tables.include? "omeka_collections"

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
end
