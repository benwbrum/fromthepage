class AddTextOnlyPdfToBulkExport < ActiveRecord::Migration[6.0]
  def change
    add_column :bulk_exports, :text_only_pdf_work, :boolean
  end
end
