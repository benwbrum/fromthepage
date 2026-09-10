class AddEditMetadataAfterSplitToWorks < ActiveRecord::Migration[7.2]
  def change
    add_column :works, :edit_metadata_after_split, :boolean, default: false, null: false
  end
end
