class AddIndexOnNotes < ActiveRecord::Migration
  def change
    add_index :notes, :page_id
  end
end
