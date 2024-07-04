class AddWorkIdToBulkExport < ActiveRecord::Migration[5.0]

  def change
    add_reference :bulk_exports, :work, null: true, foreign_key: true
  end

end
