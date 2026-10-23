class AddWorkMetadataCsvToBulkExport < ActiveRecord::Migration[5.0]
  def change
    add_column :bulk_exports, :work_metadata_csv, :boolean, default: false
  end
end
