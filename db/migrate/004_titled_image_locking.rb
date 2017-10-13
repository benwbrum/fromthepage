class TitledImageLocking < ActiveRecord::Migration
  def self.up
#    add_column :titled_images, :lock_version, :integer, :default => 0
  end

  def self.down
#    remove_column :titled_images, :lock_version
  end
end
