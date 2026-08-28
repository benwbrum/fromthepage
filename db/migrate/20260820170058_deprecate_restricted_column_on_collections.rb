class DeprecateRestrictedColumnOnCollections < ActiveRecord::Migration[7.2]
  def up
    remove_column :collections, :restricted
  end

  def down
    add_column :collections, :restricted, :boolean, default: false
  end
end
