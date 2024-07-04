class AddFacetsEnabledToCollection < ActiveRecord::Migration[5.0]

  def change
    add_column :collections, :facets_enabled, :boolean, default: false
  end

end
