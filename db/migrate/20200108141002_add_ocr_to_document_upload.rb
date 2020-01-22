class AddOcrToDocumentUpload < ActiveRecord::Migration[5.2]
  def change
    add_column :document_uploads, :ocr, :boolean, :default => false
  end
end
