class AddMetadataToPage < ActiveRecord::Migration[5.0]

  def change
    add_column :pages, :metadata, :text
  end

end
