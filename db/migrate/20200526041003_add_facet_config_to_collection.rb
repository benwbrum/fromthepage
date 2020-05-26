class AddFacetConfigToCollection < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :facet_config, :json
  end
end
