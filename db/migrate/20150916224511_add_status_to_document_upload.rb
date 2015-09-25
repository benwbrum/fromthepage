class AddStatusToDocumentUpload < ActiveRecord::Migration
  def change
    add_column :document_uploads, :status, :string, :default => 'new'
  end
end
