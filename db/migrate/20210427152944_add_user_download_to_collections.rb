class AddUserDownloadToCollections < ActiveRecord::Migration[5.0]
  def change
    add_column :collections, :user_download, :boolean, default: false
  end
end
