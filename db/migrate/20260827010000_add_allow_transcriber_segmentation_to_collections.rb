class AddAllowTranscriberSegmentationToCollections < ActiveRecord::Migration[7.2]
  def change
    add_column :collections, :allow_transcriber_segmentation, :boolean, default: false, null: false
  end
end
