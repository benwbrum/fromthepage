class AddIndexToOmekaFile < ActiveRecord::Migration
  def change
    add_index :omeka_files, :omeka_id
  end
end
