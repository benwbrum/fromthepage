class AddInstitutionSignatureToCollection < ActiveRecord::Migration[6.0]

  def change
    add_column :collections, :institution_signature, :boolean, default: false
  end

end
