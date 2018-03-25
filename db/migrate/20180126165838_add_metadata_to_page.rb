class AddMetadataToPage < ActiveRecord::Migration
  def change
    add_column :pages, :metadata, :text
  end
end
