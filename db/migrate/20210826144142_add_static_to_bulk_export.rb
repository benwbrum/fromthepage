class AddStaticToBulkExport < ActiveRecord::Migration[6.0]

  def change
    add_column :bulk_exports, :static, :boolean
  end

end
