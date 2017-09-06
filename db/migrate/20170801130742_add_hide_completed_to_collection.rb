class AddHideCompletedToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :hide_completed, :boolean, default: true
  end
end
