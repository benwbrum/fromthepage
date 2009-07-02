class AddContactToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :intro_block, :text
    add_column :collections, :footer_block, :string, :limit => 2000
  end

  def self.down
    remove_column :collections, :intro_block
    remove_column :collections, :footer_block
  end
end
