class AddApiKeyToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :api_key, :string
  end
end
