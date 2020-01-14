class AddOcrToDocumentUpload < ActiveRecord::Migration
  def change
    add_column :document_uploads, :ocr, :boolean, :default => false
  end
end
