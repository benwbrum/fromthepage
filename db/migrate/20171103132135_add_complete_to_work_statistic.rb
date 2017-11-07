class AddCompleteToWorkStatistic < ActiveRecord::Migration
  def change
    add_column :work_statistics, :complete, :integer
    add_column :work_statistics, :translation_complete, :integer
  end
end
