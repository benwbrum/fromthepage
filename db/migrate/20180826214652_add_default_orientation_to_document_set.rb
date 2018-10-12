class AddDefaultOrientationToDocumentSet < ActiveRecord::Migration
  def change
    add_column :document_sets, :default_orientation, :string
  end
end
