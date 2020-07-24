class CreateWorkFacets < ActiveRecord::Migration[5.0]
  def change
    create_table :work_facets do |t|
      t.string :s0
      t.string :s1
      t.string :s2
      t.string :s3
      t.string :s4
      t.string :s5
      t.string :s6
      t.string :s7
      t.string :s8
      t.string :s9
      t.date :d0
      t.date :d1
      t.date :d2
      t.references :work, null: false, foreign_key: true

      t.timestamps
    end
  end
end
