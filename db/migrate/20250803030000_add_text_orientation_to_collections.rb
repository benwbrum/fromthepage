class AddTextOrientationToCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :text_orientation, :string
  end
end