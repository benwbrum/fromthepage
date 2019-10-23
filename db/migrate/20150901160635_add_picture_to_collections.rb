class AddPictureToCollections < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :picture, :string
  end
end
