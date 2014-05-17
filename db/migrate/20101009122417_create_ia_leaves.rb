class CreateIaLeaves < ActiveRecord::Migration
  def self.up
    create_table :ia_leaves do |t|
      t.integer :ia_work_id
      t.integer :page_id #foreign key to FromThePage pages

      t.integer :page_w
      t.integer :page_h
      t.integer :leaf_number
      t.string  :page_number
      t.string  :page_type

      t.timestamps
    end
  end

  def self.down
    drop_table :ia_leaves
  end
end
