class CreateWorks < ActiveRecord::Migration[5.2]
  def self.up
    create_table :works do |t|
      t.column :title, :string, :limit => 255
      t.column :description, :string, :limit => 4000
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :works
  end
end
