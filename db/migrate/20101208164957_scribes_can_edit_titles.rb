class ScribesCanEditTitles < ActiveRecord::Migration
  def self.up
      add_column :works, :scribes_can_edit_titles, :boolean, :default => false
  end

  def self.down
      remove_column :works, :scribes_can_edit_titles
  end
end
