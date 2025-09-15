class AddLegendToCollections < ActiveRecord::Migration[7.1]
  def change
    add_column :collections, :legend, :text
  end
end