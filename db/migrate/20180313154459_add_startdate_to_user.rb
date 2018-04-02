class AddStartdateToUser < ActiveRecord::Migration
  def change
    add_column :users, :start_date, :datetime
  end
end
