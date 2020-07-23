class AddGuestToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :guest, :boolean
  end
end
