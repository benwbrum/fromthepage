class AddZeroIndexToBulkExport < ActiveRecord::Migration[6.0]
  def change
    add_column :bulk_exports, :plaintext_verbatim_zero_index_page, :boolean, default: false
  end
end
