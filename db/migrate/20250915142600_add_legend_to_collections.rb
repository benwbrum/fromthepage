class AddLegendToCollections < ActiveRecord::Migration[7.2]
  def change
    add_column :collections, :legend, :text
  end
end
