class AddVisibilityFieldToCollection < ActiveRecord::Migration[7.2]
  def change
    add_column :collections, :visibility, :string, default: 'public'
  end
end
