class AddMetadataFieldsToWork < ActiveRecord::Migration[6.0]

  def change
    add_column :works, :genre, :string
    add_column :works, :source_location, :string
    add_column :works, :source_collection_name, :string
    add_column :works, :source_box_folder, :string
    add_column :works, :in_scope, :boolean, default: true
    add_column :works, :editorial_notes, :text
    add_column :works, :document_date, :string
  end

end
