class ChangeUserAboutColumn < ActiveRecord::Migration[5.0]

  def up
    change_column :users, :about, :text
  end

  def down
    change_column :users, :about, :string
  end

end
