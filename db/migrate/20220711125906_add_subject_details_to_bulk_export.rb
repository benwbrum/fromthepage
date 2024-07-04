class AddSubjectDetailsToBulkExport < ActiveRecord::Migration[6.0]

  def change
    add_column :bulk_exports, :subject_details_csv_collection, :boolean
  end

end
