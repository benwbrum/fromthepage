class CreateImageSets < ActiveRecord::Migration
  def self.up
=begin    create_table :image_sets do |t|
      # the path where the images live
      t.column :path, :string , :limit => 255
      t.column :title_format, :string , :limit => 255
      t.column :created_on, :datetime
    end
=end  
  end

  def self.down
#    drop_table :image_sets
  end
end
