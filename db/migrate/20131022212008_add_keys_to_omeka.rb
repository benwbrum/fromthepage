class AddKeysToOmeka < ActiveRecord::Migration[5.2]
  def self.up
    add_column :omeka_files, :page_id, :integer unless column_exists? :omeka_files, :page_id

    add_column :omeka_items, :work_id, :integer unless column_exists? :omeka_items, :work_id
  end

  def self.down
    remove_column :omeka_files, :page_id

    remove_column :omeka_items, :work_id
  end
end
