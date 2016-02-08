class AddSupportsDocumentSetsToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :supports_document_sets, :boolean, :default => false
  end
end
