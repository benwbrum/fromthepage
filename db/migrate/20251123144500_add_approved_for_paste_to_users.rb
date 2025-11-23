class AddApprovedForPasteToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :approved_for_paste, :boolean, default: false, null: false
    add_index :users, :approved_for_paste
  end
end
