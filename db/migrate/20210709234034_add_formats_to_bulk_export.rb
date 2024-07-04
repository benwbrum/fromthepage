class AddFormatsToBulkExport < ActiveRecord::Migration[6.0]

  def change
    add_column :bulk_exports, :text_pdf_work, :boolean
    add_column :bulk_exports, :text_docx_work, :boolean
  end

end
