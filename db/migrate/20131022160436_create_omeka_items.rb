class CreateOmekaItems < ActiveRecord::Migration
  def change
    create_table :omeka_items do |t|
      t.string :title
      t.string :subject
      t.string :description
      t.string :rights
      t.string :creator
      t.string :format
      t.string :coverage
      t.integer :omeka_site_id
      t.integer :omeka_id
      t.string :omeka_url
      t.integer :omeka_collection_id
      t.integer :user_id

      t.timestamps
    end
  end
end
