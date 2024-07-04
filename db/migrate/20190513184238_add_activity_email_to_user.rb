class AddActivityEmailToUser < ActiveRecord::Migration[5.0]

  def change
    add_column :users, :activity_email, :boolean
  end

end
