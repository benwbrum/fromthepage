class AddIdentifierToWork < ActiveRecord::Migration[5.2]
  def change
    add_column :works, :identifier, :string
  end
end
