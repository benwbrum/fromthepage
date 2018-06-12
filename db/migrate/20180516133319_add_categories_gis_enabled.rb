class AddCategoriesGisEnabled < ActiveRecord::Migration
  def change
    add_column :categories, :gis_enabled, :boolean, null: false, default: false
  end
end
