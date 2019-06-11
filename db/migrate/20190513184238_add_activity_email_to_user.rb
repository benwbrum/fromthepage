class AddActivityEmailToUser < ActiveRecord::Migration
  def change
    add_column :users, :activity_email, :boolean
  end
end
