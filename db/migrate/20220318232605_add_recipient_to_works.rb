class AddRecipientToWorks < ActiveRecord::Migration[6.0]
  def change
    add_column :works, :recipient, :string
  end
end
