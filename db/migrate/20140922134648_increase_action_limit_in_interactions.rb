class IncreaseActionLimitInInteractions < ActiveRecord::Migration[5.2]
  def change
		change_column(:interactions, :action, :string, :limit => 100 )
  end
end
