class AddDefaultOrientationToDocumentSet < ActiveRecord::Migration[5.2]
  def change
    add_column :document_sets, :default_orientation, :string
  end
end
