class AddOriginalMetadataToWork < ActiveRecord::Migration[5.0]

  def change
    add_column :works, :original_metadata, :text
  end

end
