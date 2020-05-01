class AddApiAccessToCollections < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :api_access, :boolean, default: false
  end
end
