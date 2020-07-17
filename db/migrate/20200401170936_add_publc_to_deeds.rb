class AddPublcToDeeds < ActiveRecord::Migration[6.0]
  def change
    add_column :deeds, :is_public, :boolean, default: true
  end
end
