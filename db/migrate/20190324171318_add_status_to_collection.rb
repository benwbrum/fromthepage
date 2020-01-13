class AddStatusToCollection < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :is_active, :boolean, :default => true
  end
end