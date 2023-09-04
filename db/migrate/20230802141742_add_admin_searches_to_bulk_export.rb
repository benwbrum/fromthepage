class AddAdminSearchesToBulkExport < ActiveRecord::Migration[6.0]
  def change
    add_column :bulk_exports, :admin_searches, :boolean
  end
end
