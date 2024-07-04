class AddIndexToIaLeavesPageId < ActiveRecord::Migration[5.0]

  def change
    add_index :ia_leaves, :page_id
  end

end
