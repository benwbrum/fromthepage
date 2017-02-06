class AddAccountTypeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :account_type, :string
    add_column :users, :paid_date, :datetime
  end
end
