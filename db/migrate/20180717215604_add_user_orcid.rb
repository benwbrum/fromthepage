class AddUserOrcid < ActiveRecord::Migration
  def change
    add_column :users, :orcid, :string
  end
end
