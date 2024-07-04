class AddPictureToCollections < ActiveRecord::Migration[5.0]

  def change
    add_column :collections, :picture, :string
  end

end
