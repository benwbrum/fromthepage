class AddIndexToOmekaFile < ActiveRecord::Migration[5.0]
  def change
    add_index :omeka_files, :omeka_id
  end
end
