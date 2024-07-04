class AddMetadataDescriptionModeToCollection < ActiveRecord::Migration[6.0]

  def change
    add_column :collections, :data_entry_type, :string, default: Collection::DataEntryType::TEXT_ONLY
  end

end
