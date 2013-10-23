class CreateOmekaFiles < ActiveRecord::Migration
  def change
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
