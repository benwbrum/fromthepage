class AddDocumentSetToBulkExport < ActiveRecord::Migration[5.0]

  def change
    add_reference :bulk_exports, :document_set, null: true, foreign_key: true
  end

end
