class CreateTableCells < ActiveRecord::Migration[5.0]
  def change
    create_table :table_cells do |t|
      t.references :work, index: true
      t.references :page, index: true
      t.references :section, index: true
      t.string :header
      t.string :content
      t.integer :row

      t.timestamps
    end
  end
end
