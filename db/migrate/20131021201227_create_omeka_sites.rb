class CreateOmekaSites < ActiveRecord::Migration
  def change
    create_table :omeka_sites do |t|
      t.string :title
      t.string :api_url
      t.string :api_key
      t.integer :user_id

      t.timestamps
    end
  end
end
