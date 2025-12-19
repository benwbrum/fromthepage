class AddHelpToUsers < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :help, :text
  end

  def down
    remove_column :users, :help
  end
end
