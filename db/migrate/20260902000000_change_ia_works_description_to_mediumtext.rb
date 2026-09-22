class ChangeIaWorksDescriptionToMediumtext < ActiveRecord::Migration[7.2]
  def up
    change_column :ia_works, :description, :text, limit: 16.megabytes - 1
  end

  def down
    change_column :ia_works, :description, :string, limit: 1024
  end
end
