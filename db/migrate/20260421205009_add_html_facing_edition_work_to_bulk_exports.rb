class AddHtmlFacingEditionWorkToBulkExports < ActiveRecord::Migration[7.2]
  def change
    add_column :bulk_exports, :html_facing_edition_work, :boolean
  end
end
