class ScribeAccessPerWork < ActiveRecord::Migration[5.0]
  def self.up
    add_column :works, :restrict_scribes, :boolean, default: false
  end

  def self.down
    remove_column :works, :restrict_scribes
  end
end
