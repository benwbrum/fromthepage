class AddVisibilityFieldToCollection < ActiveRecord::Migration[7.2]
  def up
    # Backsupport for CI
    unless column_exists?(:collections, :visibility)
      add_column :collections, :visibility, :string, default: 'public'
    end
  end

  def down
    remove_column :collections, :visibility
  end
end
