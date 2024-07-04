class AddMesssageboardsEnabledToCollection < ActiveRecord::Migration[6.0]

  def change
    add_column :collections, :messageboards_enabled, :boolean
  end

end
