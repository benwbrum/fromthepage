class AddSegmentationEnabledToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :segmentation_enabled, :boolean, default: false
  end
end
