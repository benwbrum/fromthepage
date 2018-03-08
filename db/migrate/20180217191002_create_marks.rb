class CreateMarks < ActiveRecord::Migration
  def change
    create_table :marks do |t|
      t.belongs_to :page, index: true
      t.text :text
      t.string :text_type
      t.text :coordinates
      t.string :shape_type
    end
  end
end
