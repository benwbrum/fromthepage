class RenameHtmlFacingEditionWorkToAccessiblePdf < ActiveRecord::Migration[7.2]
  def change
    rename_column :bulk_exports, :html_facing_edition_work, :accessible_pdf_work
  end
end
