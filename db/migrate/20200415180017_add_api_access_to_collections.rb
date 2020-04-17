class AddApiAccessToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :api_access, :boolean, default: false
  end
end
