class AddPageDetailsCsvToBulkExports < ActiveRecord::Migration[7.2]
  def change
    add_column :bulk_exports, :page_details_csv_work, :boolean, default: false
    add_column :bulk_exports, :page_details_csv_collection, :boolean, default: false
  end
end
