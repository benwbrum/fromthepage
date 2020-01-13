class AddOcrCorrectionToWorkStatistics < ActiveRecord::Migration[5.2]
  def change
    add_column :work_statistics, :corrected_pages, :integer
  end
end
