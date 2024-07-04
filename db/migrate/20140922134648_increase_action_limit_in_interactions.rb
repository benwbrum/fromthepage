class IncreaseActionLimitInInteractions < ActiveRecord::Migration[5.0]

  def change
    change_column(:interactions, :action, :string, limit: 100)
  end

end
