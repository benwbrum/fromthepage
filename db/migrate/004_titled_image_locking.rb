class TitledImageLocking < ActiveRecord::Migration[5.2]
  def self.up
#    add_column :titled_images, :lock_version, :integer, :default => 0
  end

  def self.down
#    remove_column :titled_images, :lock_version
  end
end
