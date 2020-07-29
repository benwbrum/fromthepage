class AddStatusToDocumentUpload < ActiveRecord::Migration[5.0]
  def change
    add_column :document_uploads, :status, :string, :default => 'new'
  end
end
