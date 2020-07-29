class AddSupportsDocumentSetsToCollection < ActiveRecord::Migration[5.0]
  def change
    add_column :collections, :supports_document_sets, :boolean, :default => false
  end
end
