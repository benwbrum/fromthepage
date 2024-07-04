class AddMetadataDescriptionToWork < ActiveRecord::Migration[5.0]

  def change
    add_column :works, :metadata_description, :text
  end

end
