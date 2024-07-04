class ChangeBulkExportCollection < ActiveRecord::Migration[5.0]

  def change
    change_column_null :bulk_exports, :collection_id, true
  end

end
