class CreateOmekaFiles < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.tables.include? "omeka_files"
      create_table :omeka_files do |t|
        t.integer :omeka_id
        t.integer :omeka_item_id
        t.string :mime_type
        t.string :fullsize_url
        t.string :thumbnail_url
        t.string :original_filename
        t.integer :omeka_order
  
        t.timestamps
      end
    end
  end
end
