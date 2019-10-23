class AddAccountTypeToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :account_type, :string
    add_column :users, :paid_date, :datetime
  end
end
