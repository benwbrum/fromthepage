class AddPublcToDeeds < ActiveRecord::Migration[5.0]

  def change
    add_column :deeds, :is_public, :boolean, default: true
  end

end
