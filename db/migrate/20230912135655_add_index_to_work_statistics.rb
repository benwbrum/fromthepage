class AddIndexToWorkStatistics < ActiveRecord::Migration[6.0]
  def change
    add_index :work_statistics, [:work_id, :line_count]
  end
end
