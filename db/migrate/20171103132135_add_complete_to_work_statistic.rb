class AddCompleteToWorkStatistic < ActiveRecord::Migration[5.0]

  def change
    add_column :work_statistics, :complete, :integer
    add_column :work_statistics, :translation_complete, :integer
  end

end
