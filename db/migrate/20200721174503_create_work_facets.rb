class CreateWorkFacets < ActiveRecord::Migration[5.0]

  def change
    create_table :work_facets do |t|
      t.string :s0, limit: 512
      t.string :s1, limit: 512
      t.string :s2, limit: 512
      t.string :s3, limit: 512
      t.string :s4, limit: 512
      t.string :s5, limit: 512
      t.string :s6, limit: 512
      t.string :s7, limit: 512
      t.string :s8, limit: 512
      t.string :s9, limit: 512
      t.date :d0
      t.date :d1
      t.date :d2
      t.references :work, null: false, foreign_key: true

      t.timestamps
    end
  end

end
