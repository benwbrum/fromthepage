class AddOwnerContactToNotification < ActiveRecord::Migration[6.0]
  def change
    add_column :notifications, :owner_contact, :boolean, default: true
  end
end
