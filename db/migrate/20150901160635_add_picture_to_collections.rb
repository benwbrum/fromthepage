class AddPictureToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :picture, :string
  end
end
