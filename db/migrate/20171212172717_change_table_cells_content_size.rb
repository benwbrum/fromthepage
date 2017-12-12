class ChangeTableCellsContentSize < ActiveRecord::Migration
  def up
    change_column :table_cells, :content, :text
  end
  def down
    change_column :table_cells, :content, :string
  end
end
