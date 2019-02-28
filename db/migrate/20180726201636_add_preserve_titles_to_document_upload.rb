class AddPreserveTitlesToDocumentUpload < ActiveRecord::Migration
  def change
    add_column :document_uploads, :preserve_titles, :boolean, :default => false
  end
end
