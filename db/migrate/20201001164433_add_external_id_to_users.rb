class AddExternalIdToUsers < ActiveRecord::Migration[5.0]

  def change
    add_column :users, :external_id, :string
  end

end
