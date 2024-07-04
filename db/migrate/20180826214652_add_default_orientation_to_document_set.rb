class AddDefaultOrientationToDocumentSet < ActiveRecord::Migration[5.0]

  def change
    add_column :document_sets, :default_orientation, :string
  end

end
