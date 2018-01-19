class AddDeletedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :deleted, :boolean, default: false
  end
end
