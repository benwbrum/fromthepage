class RemoveInstitutionSignatureFromCollection < ActiveRecord::Migration[6.0]

  def change
    remove_column :collections, :institution_signature, :boolean
  end

end
