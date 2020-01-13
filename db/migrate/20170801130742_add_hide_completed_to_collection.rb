class AddHideCompletedToCollection < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :hide_completed, :boolean, default: true
  end
end
