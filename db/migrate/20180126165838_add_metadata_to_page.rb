class AddMetadataToPage < ActiveRecord::Migration[5.2]
  def change
    add_column :pages, :metadata, :text
  end
end
