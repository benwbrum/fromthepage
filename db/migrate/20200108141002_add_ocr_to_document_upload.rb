class AddOcrToDocumentUpload < ActiveRecord::Migration[6.0]
  def change
    add_column :document_uploads, :ocr, :boolean, :default => false
  end
end
