class ChangeIaWorksDescriptionSize < ActiveRecord::Migration[5.2]
  def up
    change_column :ia_works, :description, :string, :limit => 1024
  end
  def down
    change_column :ia_works, :description, :string, :limit => 255
  end
end
