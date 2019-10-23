class AddStatusToDocumentUpload < ActiveRecord::Migration[5.2]
  def change
    add_column :document_uploads, :status, :string, :default => 'new'
  end
end
