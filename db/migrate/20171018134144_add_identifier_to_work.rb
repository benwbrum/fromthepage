class AddIdentifierToWork < ActiveRecord::Migration[5.0]

  def change
    add_column :works, :identifier, :string
  end

end
