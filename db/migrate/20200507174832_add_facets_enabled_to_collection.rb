class AddFacetsEnabledToCollection < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :facets_enabled, :boolean, default: false
  end
end
