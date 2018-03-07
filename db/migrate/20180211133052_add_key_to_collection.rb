class AddKeyToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :license_key, :string
  end
end
