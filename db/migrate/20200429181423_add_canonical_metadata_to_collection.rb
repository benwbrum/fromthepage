class AddCanonicalMetadataToCollection < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :canonical_metadata, :json
  end
end
