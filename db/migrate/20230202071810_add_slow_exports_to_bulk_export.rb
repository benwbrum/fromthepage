class AddSlowExportsToBulkExport < ActiveRecord::Migration[6.0]

  def change
    # there is no place to add this to the export UI
    add_column :bulk_exports, :owner_mailing_list, :boolean
    add_column :bulk_exports, :owner_detailed_activity, :boolean
    # we might be able to add this to the export UI if we were able to specify arguments
    add_column :bulk_exports, :collection_activity, :boolean
    add_column :bulk_exports, :collection_contributors, :boolean
    # arguments (currently start date/end date in contributors tab)
    add_column :bulk_exports, :report_arguments, :string
  end

end
