class AddIndexOnNotes < ActiveRecord::Migration[5.2]
  def change
    add_index :notes, :page_id
  end
end
