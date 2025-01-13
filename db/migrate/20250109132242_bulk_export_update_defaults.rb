class BulkExportUpdateDefaults < ActiveRecord::Migration[6.1]
  def up
    change_column_default :bulk_exports, :use_uploaded_filename, true
    change_column_default :bulk_exports, :status, :new
  end

  def down
    change_column_default :bulk_exports, :use_uploaded_filename, false
    change_column_default :bulk_exports, :status, null
  end
end
