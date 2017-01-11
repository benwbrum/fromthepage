class AddOcrCorrectionToWorkStatistics < ActiveRecord::Migration
  def change
    add_column :work_statistics, :corrected_pages, :integer
  end
end
