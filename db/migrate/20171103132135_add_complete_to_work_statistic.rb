class AddCompleteToWorkStatistic < ActiveRecord::Migration[5.2]
  def change
    add_column :work_statistics, :complete, :integer
    add_column :work_statistics, :translation_complete, :integer
  end
end
