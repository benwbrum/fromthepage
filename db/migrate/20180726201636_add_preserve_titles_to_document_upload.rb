class AddPreserveTitlesToDocumentUpload < ActiveRecord::Migration[5.2]
  def change
    add_column :document_uploads, :preserve_titles, :boolean, :default => false
  end
end
