class AddKeyToCollection < ActiveRecord::Migration[5.0]
  def change
    add_column :collections, :license_key, :string
  end
end
