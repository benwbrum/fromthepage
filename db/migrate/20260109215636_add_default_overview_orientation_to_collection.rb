class AddDefaultOverviewOrientationToCollection < ActiveRecord::Migration[7.0]
  def change
    add_column :collections, :default_overview_orientation, :string
  end
end
