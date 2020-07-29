class AddCategoriesGisEnabled < ActiveRecord::Migration[5.0]
  def change
    add_column :categories, :gis_enabled, :boolean, null: false, default: false
  end
end
