class AddStatusToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :is_active, :boolean, :default => true
  end
end