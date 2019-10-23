class AddDefaultOrientationToCollection < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :default_orientation, :string
  end
end
