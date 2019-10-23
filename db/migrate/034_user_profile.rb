class UserProfile < ActiveRecord::Migration[5.2]
  def self.up
    add_column :users, :location, :string
    add_column :users, :website, :string
    add_column :users, :about, :string
  end

  def self.down
    remove_column :users, :location
    remove_column :users, :website
    remove_column :users, :about
  end
end