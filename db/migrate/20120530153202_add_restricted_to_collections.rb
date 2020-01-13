class AddRestrictedToCollections < ActiveRecord::Migration[5.2]
  def self.up
    add_column :collections, :restricted, :boolean, :default => false
  end

  def self.down
    remove_column :collections, :restricted
  end
end
