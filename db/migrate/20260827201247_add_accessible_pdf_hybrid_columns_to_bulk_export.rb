class AddAccessiblePdfHybridColumnsToBulkExport < ActiveRecord::Migration[7.2]
  def change
    change_table :bulk_exports, bulk: true do |t|
      t.string :accessible_pdf_source, default: :human_only
      t.boolean :accessible_pdf_prepend_ai_warnings, default: false
    end
  end
end
