class AddUseUploadedFilenameToBulkExport < ActiveRecord::Migration[6.0]
  def change
    add_column :bulk_exports, :use_uploaded_filename, :boolean, default: false
  end
end
