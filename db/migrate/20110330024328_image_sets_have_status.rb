class ImageSetsHaveStatus < ActiveRecord::Migration
  def self.up
=begin    add_column :image_sets, :step, :string, :length => 20
    add_column :image_sets, :status, :string, :length => 10
    add_column :image_sets, :status_message, :string, :length => 200

    add_column :image_sets, :crop_band_start, :integer
    add_column :image_sets, :crop_band_height, :integer
=end  
  end

  def self.down
=begin    remove_column :image_sets, :status_message
    remove_column :image_sets, :status
    remove_column :image_sets, :step

    remove_column :image_sets, :crop_band_start
    remove_column :image_sets, :crop_band_height
=end  
  end
end
