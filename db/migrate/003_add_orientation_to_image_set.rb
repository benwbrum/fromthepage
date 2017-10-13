class AddOrientationToImageSet < ActiveRecord::Migration
  def self.up
=begin    add_column :image_sets, :orientation, :integer, :null => true
    add_column :image_sets, :original_width, :integer, :null => true
    add_column :image_sets, :original_height, :integer, :null => true
    # this one represents the number of times you can half the image
    # resolution to get to the baseline (minimum visible)
    add_column :image_sets, :original_to_base_halvings, :integer, :null => true
=end  
  end

  def self.down
=begin    remove_column :image_sets, :orientation
    remove_column :image_sets, :original_width
    remove_column :image_sets, :original_height
    remove_column :image_sets, :original_to_base_halvings
=end  
  end
end
