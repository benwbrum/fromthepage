class CreateTexFigures < ActiveRecord::Migration[5.2]
  def change
    create_table :tex_figures do |t|
      t.references :page, index: true
      t.integer :position
      t.text :source

      t.timestamps
    end
  end
end
