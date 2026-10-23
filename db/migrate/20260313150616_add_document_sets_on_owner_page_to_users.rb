class AddDocumentSetsOnOwnerPageToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :document_sets_on_owner_page, :boolean, default: false
  end
end
