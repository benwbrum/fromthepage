class ChangeTableCellsForFields < ActiveRecord::Migration[5.0]

  def up
    change_column :table_cells, :content, :text
    add_column :table_cells, :transcription_field_id, :integer
  end

  def down
    change_column :table_cells, :content, :string
    remove_column :table_cells, :transcription_field_id, :integer
  end

end
