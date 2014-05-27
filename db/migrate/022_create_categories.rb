class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.column :title, :string, :size => 255

      # heirarchy
      t.column :parent_id, :integer

      # foreign key to collection
      t.column :collection_id, :integer

      # metadata stuff
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :categories
  end
end
