class InteractionTableHasStatusAndOrigin < ActiveRecord::Migration[5.2]
  def self.up
    add_column :interactions, :status, :string, :limit => 10
    add_column :interactions, :origin_link, :string, :limit => 20
    remove_column :interactions, :description
    change_column :interactions, :params, :string, :limit => 255
  end

  def self.down
    remove_column :interactions, :status
    remove_column :interactions, :origin_link
    add_column :interactions, :description, :string, :limit => 255
    change_column :interactions, :params, :string, :limit => 128
  end
end
