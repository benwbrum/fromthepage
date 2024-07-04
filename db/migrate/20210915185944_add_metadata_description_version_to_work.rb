class AddMetadataDescriptionVersionToWork < ActiveRecord::Migration[5.0]

  def change
    add_reference :works, :metadata_description_version, null: true, foreign_key: true
  end

end
