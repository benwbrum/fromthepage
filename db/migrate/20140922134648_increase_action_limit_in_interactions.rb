class IncreaseActionLimitInInteractions < ActiveRecord::Migration
  def change
		change_column(:interactions, :action, :string, :limit => 100 )
  end
end
