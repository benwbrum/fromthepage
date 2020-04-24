class AddPublcToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :is_public, :boolean, default: true
  end
end
