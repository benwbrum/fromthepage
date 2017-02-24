class AddGuestToUser < ActiveRecord::Migration
  def change
    add_column :users, :guest, :boolean
  end
end
