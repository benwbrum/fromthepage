class RenamePrintNameToRealName < ActiveRecord::Migration
  def change
    rename_column :users, :print_name, :real_name
  end
end
