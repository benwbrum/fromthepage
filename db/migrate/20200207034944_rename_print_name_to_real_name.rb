class RenamePrintNameToRealName < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :print_name, :real_name
  end
end
