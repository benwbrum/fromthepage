class ImageSetOwner < ActiveRecord::Migration
  def self.up
#    add_column :image_sets, :owner_user_id, :integer
  end

  def self.down
#    remove_column :image_sets, :owner_user_id
  end
end
