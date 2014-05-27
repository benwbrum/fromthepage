class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      # data
      t.column :title, :string, :limit => 255
      t.column :body, :text

      # associations
      t.column :user_id,    :integer
      t.column :collection_id,    :integer
      t.column :work_id,  :integer
      t.column :page_id,  :integer

      # internals
      t.column :parent_id, :integer
      t.column :depth, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :notes
  end
end
