class AddSplitFromWorkIdToWorks < ActiveRecord::Migration[7.2]
  def change
    add_column :works, :split_from_work_id, :integer, default: nil
    add_index :works, :split_from_work_id
  end
end
