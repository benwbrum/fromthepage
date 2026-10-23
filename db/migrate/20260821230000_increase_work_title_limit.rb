class IncreaseWorkTitleLimit < ActiveRecord::Migration[7.2]
  def change
    change_column :works, :title, :string, limit: 1028
    change_column :ia_works, :title, :string, limit: 1028
  end
end
