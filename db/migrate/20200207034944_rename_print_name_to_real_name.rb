class RenamePrintNameToRealName < ActiveRecord::Migration[5.0]

  def change
    rename_column :users, :print_name, :real_name
  end

end
