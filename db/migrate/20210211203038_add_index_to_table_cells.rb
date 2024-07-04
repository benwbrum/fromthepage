class AddIndexToTableCells < ActiveRecord::Migration[5.0]

  def change
    add_index :table_cells, :transcription_field_id
  end

end
