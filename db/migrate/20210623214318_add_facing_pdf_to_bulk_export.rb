class AddFacingPdfToBulkExport < ActiveRecord::Migration[6.0]

  def change
    add_column :bulk_exports, :facing_edition_work, :boolean
  end

end
