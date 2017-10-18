class AddIdentifierToWork < ActiveRecord::Migration
  def change
    add_column :works, :identifier, :string
  end
end
