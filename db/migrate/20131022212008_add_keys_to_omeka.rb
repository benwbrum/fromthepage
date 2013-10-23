class AddKeysToOmeka < ActiveRecord::Migration
  def self.up
    add_column :omeka_files, :page_id, :integer

    add_column :omeka_items, :work_id, :integer

  end

  def self.down
    remove_column :omeka_files, :page_id

    remove_column :omeka_items, :work_id
  end
end
