class AddDocumentSetIdToDocumentUpload < ActiveRecord::Migration[7.2]
  def change
    change_table :document_uploads, bulk: true do |t|
      t.integer :document_set_id, null: true
      t.index :document_set_id
    end
  end
end
