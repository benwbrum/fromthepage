class AddDefaultOrientationToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :default_orientation, :string
  end
end
