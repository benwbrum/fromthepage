class CreateLayers < ActiveRecord::Migration
  def change
    create_table :layers do |t|
      t.string :name
      t.references :page, index: true

      t.timestamps
    end
  end
end
