class AddFkToNotes < ActiveRecord::Migration[6.1]
  def change
    change_table :notes, bulk: true do |t|
      t.foreign_key :pages, column: :page_id, on_delete: :cascade
      t.foreign_key :works, column: :work_id, on_delete: :cascade
      t.foreign_key :collections, column: :collection_id, on_delete: :cascade
    end
  end
end
