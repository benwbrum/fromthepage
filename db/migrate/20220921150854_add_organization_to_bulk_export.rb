class AddOrganizationToBulkExport < ActiveRecord::Migration[6.0]
  def change
    add_column :bulk_exports, :organization, :string, default: BulkExport::Organization::WORK_THEN_FORMAT
  end
end
