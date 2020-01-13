class AddPictureToWorks < ActiveRecord::Migration[5.2]
  def change
    add_column :works, :picture, :string
    add_column :works, :featured_page, :integer
  end
end
