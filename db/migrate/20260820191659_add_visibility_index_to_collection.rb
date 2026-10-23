class AddVisibilityIndexToCollection < ActiveRecord::Migration[7.2]
  def change
    add_index :collections, :visibility
  end
end
