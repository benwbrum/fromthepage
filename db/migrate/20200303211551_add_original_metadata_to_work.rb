class AddOriginalMetadataToWork < ActiveRecord::Migration[4.2]
  def change
    add_column :works, :original_metadata, :text
  end
end
