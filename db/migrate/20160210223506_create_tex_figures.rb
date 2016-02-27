class CreateTexFigures < ActiveRecord::Migration
  def change
    create_table :tex_figures do |t|
      t.references :page, index: true
      t.integer :position
      t.text :source

      t.timestamps
    end
  end
end
