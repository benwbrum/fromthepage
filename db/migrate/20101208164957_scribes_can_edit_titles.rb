class ScribesCanEditTitles < ActiveRecord::Migration[5.2]
  def self.up
      add_column :works, :scribes_can_edit_titles, :boolean, :default => false
  end

  def self.down
      remove_column :works, :scribes_can_edit_titles
  end
end
