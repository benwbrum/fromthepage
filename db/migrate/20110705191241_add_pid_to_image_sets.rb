class AddPidToImageSets < ActiveRecord::Migration
  def self.up
    add_column :image_sets, :rotate_pid, :integer
    add_column :image_sets, :shrink_pid, :integer
    add_column :image_sets, :crop_pid, :integer

  end

  def self.down
    remove_column :image_sets, :rotate_pid
    remove_column :image_sets, :shrink_pid
    remove_column :image_sets, :crop_pid

  end
end
