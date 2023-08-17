class AddCollectionNotesToBulkExports < ActiveRecord::Migration[6.0]
  def change
    add_column :bulk_exports, :notes_csv, :boolean
  end
end
