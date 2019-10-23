class AddActivityEmailToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :activity_email, :boolean
  end
end
